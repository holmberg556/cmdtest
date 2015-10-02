
Gem::Specification.new do |s|
    s.name        = 'cmdtest'
    s.version     = '0.1.0'
    s.date        = '2015-09-21'
    s.summary     = "Cmdtest, xUnit style test fo commands"
    s.description = "???"
    s.authors     = ["Johan Holmberg"]
    s.email       = 'holmberg556@gmail.com'
    s.files       = [
        'lib/cmdtest/argumentparser.rb',
        'lib/cmdtest/baselogger.rb',
        'lib/cmdtest/cmdeffects.rb',
        'lib/cmdtest/consolelogger.rb',
        'lib/cmdtest/fileinfo.rb',
        'lib/cmdtest/fssnapshot.rb',
        'lib/cmdtest/junitfile.rb',
        'lib/cmdtest/junitlogger.rb',
        'lib/cmdtest/methodfilter.rb',
        'lib/cmdtest/notify.rb',
        'lib/cmdtest/output.rb',
        'lib/cmdtest/testcase.rb',
        'lib/cmdtest/util.rb',
        'lib/cmdtest/workdir.rb',
    ]
    s.executables << "cmdtest.rb"
    s.homepage =
        'https://bitbucket.org/holmberg556/cmdtest'
    s.license = 'GNU'
end
