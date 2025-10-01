require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Services', 'app/services'
  add_group 'Jobs', 'app/jobs'
  add_group 'Helpers', 'app/helpers'

  minimum_coverage 90
end
