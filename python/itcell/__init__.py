import saliweb.backend
import os, sys, stat

class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.SGERunner

    def run(self):
        # TODO
        os.chmod(".", 0775)
        par = open('input.txt', 'r')
        input_line = par.readline().strip()
        
        script = """
module load sali-libraries\n
perl /netapp/sali/dina/bayer/ITCell/scripts/runITCell.pl %s >& itcell.log
""" % (input_line)

        r = self.runnercls(script)
        r.set_sge_options('-l arch=linux-x64,mem_free=4G -p 0')
        return r

    def complete(self):
        os.chmod(".", 0775)


def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)

