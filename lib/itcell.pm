package itcell;
use saliweb::frontend;
use strict;
use Error qw(:try);
use Scalar::Util qw(looks_like_number);

our @ISA = "saliweb::frontend";

sub new {
    return saliweb::frontend::new(@_, "##CONFIG##");
}

sub get_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    return [
        $q->a({-href=>$self->index_url}, "ITCell Home"),
        $q->a({-href=>$self->about_url}, "About ITCell"),
        $q->a({-href=>$self->help_url}, "Help"),
        $q->a({-href=>$self->queue_url}, "Current Queue")
        ];
}

sub get_header_page_title {
  return "<table> <tbody> <tr> <td>
  <table><tr><td><img src=\"//modbase.compbio.ucsf.edu/itcell/html/logo.png\" alt='ITCell' align = 'left' height = '40' /></td></tr>
         <tr><td><h3><font color='#B22222'> Integrative T-cell epitope prediction</font></h3> </td></tr></table>
      </td> <td><img src=\"//modbase.compbio.ucsf.edu/itcell/html/logo2.png\" height = '70' alt='ITCell logo'/></td></tr>
  </tbody>
  </table>\n";
}


sub get_footer {
    my $self = shift;
    my $htmlroot = $self->htmlroot;
    return <<FOOTER;
<div id="address">
<center>
<hr />
Contact:
<script type='text/javascript'>escramble(\"dina\",\"salilab.org\")</script>
</center>
</div>
FOOTER
}

sub get_index_page {
  my $self = shift;
  my $q = $self->cgi;

  return

    $q->start_form({-name=>"itcell_form", -method=>"post", -action=>$self->submit_url}) .

    $q->start_table({ -border=>0, -cellpadding=>5, -cellspacing=>0}) .
      $q->Tr($q->td('Select MHC type or upload peptide-MHC structure in PDB format')) . $q->end_table .

    $q->start_table({ -border=>0, -cellpadding=>5, -cellspacing=>0, -width=>'99%'}) .
      $q->Tr($q->td({ -align=>'left'}, [$q->a({-href => $self->help_url . "#mhc"}, $q->b('MHC type'))]),
             $q->td({ -align=>'left'}, [$q->popup_menu(-name=>'mhctype', -default=>'None',
                          -values=>['None', 
                                    'DRB1*0101','DRB1*0102','DRB1*0301','DRB1*0401','DRB1*0402','DRB1*0404','DRB1*0405',
                                    'DRB1*0407','DRB1*0701','DRB1*0801','DRB1*0802','DRB1*1101','DRB1*1104','DRB1*1201',
                                    'DRB1*1301','DRB1*1302','DRB1*1401','DRB1*1501','DRB1*1601','DRB4*0101','DRB4*0103',
                                    'DRB5*0101','DQA1*0501-DQB1*0201','DQA1*0102-DQB1*0502','DQA1*0301-DQB1*0302'])]) .
             $q->td({ -align=>'left'}, [$q->b('or') . ' upload PDB file: ' . $q->filefield({-name=>'mhcpdbfile', -size => 10})])) .

    $q->Tr($q->td({ -align=>'left'}, [$q->a({-href => $self->help_url . "#tcrfile"}, $q->b('TCR structure'))]),
           $q->td({ -align=>'left'}, [$q->filefield({-name=>'tcrfile', -size => 10})])) .

    $q->Tr($q->td({ -align=>'left'}, [$q->a({-href => $self->help_url . "#sequence"}, $q->b('Antigen sequence(s) (FASTA format)'))])) .

    $q->Tr($q->td({ -align=>'left', -colspan=>2}, $q->textarea('antigen','',10,80))) .

    $q->Tr($q->td({ -align=>'left'}, [$q->a({-href => $self->help_url . "#email"}, $q->b('e-mail address'))]),
           $q->td({ -align=>'left'}, [$q->textfield({-name => 'email'})]),
           $q->td({ -align=>'left'}, ['(the results are sent to this address)'])) .

    $q->Tr($q->td({ -align=>'left'}, [$q->a({-href => $self->help_url . "#jobname"}, 'Job name')]),
           $q->td({ -align=>'left'}, [$q->textfield({-name => 'jobname', -maxlength => 10, -size => 10})])) .

    $q->Tr($q->td({ -align=>'left', -colspan => 2}, [$q->submit(-value => 'Submit') . $q->reset(-value => 'Clear')])) .

    $q->end_table . $q->end_form;
}

sub get_submit_page {
  my $self = shift;
  my $q = $self->cgi;
  print $q->header();

  # Get form parameters
  my $mhctype = $q->param('mhctype');
  my $mhcpdbfile = $q->param('mhcpdbfile');
  my $tcrfile = $q->param('tcrfile');
  my $antigen = $q->param('antigen');
  my $email = $q->param('email');

  my $jobname = $q->param('jobname');

  # Validate input
  check_required_email($email);

  #create job directory time_stamp
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
  my $time_stamp;
  if(length $jobname > 0) {
    $time_stamp = $jobname . "_" . $sec."_".$min."_".$hour."_".$mday."_".$mon."_".$year;
  } else {
    $time_stamp = $sec."_".$min."_".$hour."_".$mday."_".$mon."_".$year;
  }
  my $job = $self->make_job($time_stamp, $self->email);
  my $jobdir = $job->directory;

  # input peptide-MHC file
  my $pmhc_file_uploaded = 0;
  my $pmhc_file_name = "";
  if (length $mhctype > 5) { # mhc type given
    $pmhc_file_name = $mhctype;
  } else { # upload file
    if(length $mhcpdbfile > 0 and $mhctype eq 'None') {
      $pmhc_file_uploaded = 1;
      my $upload_filenandle = $q->upload("pmhc_file_name");
      my $file_contents = "";
      my $atoms = 0;
      while (<$upload_filenandle>) {
        if (/^ATOM  /) { $atoms++; } #TODO: check chain IDs
        $file_contents .= $_;
      }
      if ($atoms == 0) {
        throw saliweb::frontend::InputValidationError("PDB file contains no ATOM records!");
      }
      $pmhc_file_name = "$jobdir/pMHC.pdb";
      open(INPDB, "> $pmhc_file_name")
        or throw saliweb::frontend::InternalError("Cannot open $pmhc_file_name: $!");
      print INPDB $file_contents;
      close INPDB
        or throw saliweb::frontend::InternalError("Cannot close $pmhc_file_name: $!");
      $pmhc_file_name = "pMHC.pdb";
    } else {
      throw saliweb::frontend::InputValidationError("Error in input PDB: please specify PDB code or upload file");
    }
  }

  #tcr file
  if(length $tcrfile > 0) {
    my $upload_filehandle = $q->upload("tcrfile");
    open UPLOADFILE, ">$jobdir/TCR.pdb";
    my $atoms = 0;
    while ( <$upload_filehandle> ) {
      if (/^ATOM  /) { $atoms++; print UPLOADFILE; }
    }
    close UPLOADFILE;
    my $filesize = -s "$jobdir/TCR.pdb";
    if($filesize == 0 || $atoms == 0) {
      throw saliweb::frontend::InputValidationError("You have uploaded an empty profile file: $tcrfile");
    }
  } else {
    throw saliweb::frontend::InputValidationError("Please upload valid TCR file");
  }

  # antigen sequence
  if(length $antigen > 0) {
    open SEQFILE, ">$jobdir/antigen_seq.txt";
    print SEQFILE $antigen;
    close SEQFILE;
    #TODO - validate sequence
  } else {
    throw saliweb::frontend::InputValidationError("Please provide antigen sequence");
  }

  my $input_line = $jobdir . "/input.txt";
  open(INFILE, "> $input_line")
    or throw saliweb::frontend::InternalError("Cannot open $input_line: $!");
  my $cmd = "$pmhc_file_name TCR.pdb antigen_seq.txt";
  print INFILE "$cmd\n";
  close(INFILE);

  my $data_file_name = $jobdir . "/data.txt";
  open(DATAFILE, "> $data_file_name")
    or throw saliweb::frontend::InternalError("Cannot open $data_file_name: $!");
  print DATAFILE "$mhctype $mhcpdbfile $tcrfile $email $jobname\n";
  close(DATAFILE);

  $job->submit($email);

  my $line = $job->results_url . " " . $pmhc_file_name . " " . $tcrfile . " " . $email;
  `echo $line >> ../submit.log`;

  # Inform the user of the job name and results URL
  return $q->p("Your job " . $job->name . " has been submitted.") .
    $q->p("You will receive an e-mail with results link once the job has finished");
    #$q->p("Results will be found at <a href=\"" . $job->results_url . "\">this link</a>.");

}



sub allow_file_download {
    my ($self, $file) = @_;
    return ($file eq 'itcell.log' or
            $file =~ 'scores.txt' or $file =~ 'antigen_seq.txt.out' );
}

sub get_file_mime_type {
    my ($self, $file) = @_;
    if ($file =~ /asmb.model..*chimerax/){
       return 'application/x-chimerax';
    }
    elsif ($file =~ /asmb.model..*pdb/){
       return 'chemical/x-pdb';
    }
    return 'text/plain';
}

sub get_results_page {
  my ($self, $job) = @_;
  my $q = $self->cgi;
  if (-f "scores.txt" && -s "scores.txt") {
    return $self->display_ok_job($q, $job);
  } else {
    return $self->display_failed_job($q, $job);
  }
}

sub display_ok_job {
   my ($self, $q, $job) = @_;
   my $return = ''; #$q->p("Job '<b>" . $job->name . "</b>' has completed.");
   my $sortColumn = 0;

   $return .=
     $q->start_table({ -border=>0, -cellpadding=>2, -cellspacing=>0}) .
       $q->Tr($q->th('Rank') . $q->th('Number') . $q->th('Peptide') .
              $q->th('Total Z-Score') . $q->th('pMHC Z-score') . $q->th('TCR Z-score') .
              $q->th('Total Score') . $q->th('pMHC score') . $q->th('TCR score'));

   open(DATA, "scores.txt") or die "Couldn't open results file scores.txt\n";
   my @solutions=();
   my $transCounter = 0;
   while(<DATA>) {
     chomp;
     my @tmp=split('\|',$_);
     my @tmp1 = split(' ', $tmp[0]);
     my $rank = $tmp1[0];
     my $pepnum = $tmp1[1];
     my $peptide = $tmp[1];
     my @entry = ($rank, $pepnum, $peptide, $tmp[2], $tmp[3], $tmp[4], $tmp[5], $tmp[6], $tmp[7]);
     push(@solutions, [@entry]);
     $transCounter++;
   }
   close DATA;

   # sort
   my @sortedSolutions = sort { @$a[$sortColumn] <=> @$b[$sortColumn]; } @solutions;

   # print range
   my @colors=("#cccccc","#efefef");
   for(my $i=0; $i<=$#sortedSolutions; $i++) {
     $return .= $q->Tr($q->td($sortedSolutions[$i][0]) . $q->td($sortedSolutions[$i][1]) . $q->td($sortedSolutions[$i][2]) .
                       $q->td($sortedSolutions[$i][3]) . $q->td($sortedSolutions[$i][4]) . $q->td($sortedSolutions[$i][5]) .
                       $q->td($sortedSolutions[$i][6]) . $q->td($sortedSolutions[$i][7]) . $q->td($sortedSolutions[$i][8]));
   }
   $return .= $q->end_table;
   return $return;
}

sub display_failed_job {
  my ($self, $q, $job) = @_;
  my $return= $q->p("Your job '<b>" . $job->name .
                    "</b>' failed to produce any output.");
  $return.=$q->p("This is usually caused by incorrect inputs " .
                 "(e.g. corrupt PDB file).");
  $return.= $q->p("For more information, you can download the " .
                  $q->a({-href => $job->get_results_file_url("itcell.log")}, 'ITCell log file'));
  return $return;
}

1;
