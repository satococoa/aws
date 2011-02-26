configure do
  config = YAML::load_file('config.yml')
end

get '/' do
end
