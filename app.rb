configure do
  config = YAML::load_file('config.yml')
  ACCESS = config['aws']['access']
  SECRET = config['aws']['secret']
  BUCKET = config['s3']['bucket']
  THUMBS_BUCKET = config['s3']['thumbs']
end

get '/' do
  haml :index
end

