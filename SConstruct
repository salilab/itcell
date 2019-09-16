import saliweb.build

vars = Variables('config.py')
env = saliweb.build.Environment(vars, ['conf/live.conf'], service_module='itcell')
Help(vars.GenerateHelpText(env))

env.InstallAdminTools()

Export('env')
SConscript('backend/itcell/SConscript')
SConscript('frontend/itcell/SConscript')
SConscript('html/SConscript')
SConscript('test/SConscript')
