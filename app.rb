# coding: utf-8
configure do
  config = YAML::load_file('config.yml')
  ACCESS = config['aws']['access']
  SECRET = config['aws']['secret']

  S3 = RightAws::S3.new(ACCESS, SECRET, :server => 's3-ap-southeast-1.amazonaws.com')
end

helpers do
  def number_format(val)
    val.to_s.gsub(/(.*\d)(\d\d\d)/, '\1,\2')
  end
  def get_thumbs(keys, bucket)
    thumbs = {}
    keys.each do |key|
      if !bucket.nil? && bucket.key(key.name).exists?
        thumbs[key.name] = bucket.key(key.name).public_link
      else
        thumbs[key.name] = key.public_link
      end
    end
    thumbs
  end
end

get '/' do
  haml :index
end

# bucketの操作
get '/buckets' do
  @buckets = S3.buckets
  haml :buckets
end

# 新しいbucketの作成
post '/buckets' do
  begin
    bucket = S3.bucket(params[:bucket], true, nil, :location => 'ap-southeast-1')
    # サムネイル用
    thumbs_bucket = S3.bucket(params[:bucket]+'-thumb', true, nil, :location => 'ap-southeast-1')
  rescue RightAws::AwsError => e
    @errors = []
    @errors << e.message
  end
  @buckets = S3.buckets
  haml :buckets
end

# keyの一覧
get '/bucket/:bucket_name/keys' do |bucket_name|
  @bucket = S3.bucket(bucket_name)
  thumbs_bucket = S3.bucket(bucket_name+'-thumb')

  @keys = @bucket.keys({}, true)
  @thumbs = get_thumbs(@keys, thumbs_bucket)
  haml :keys
end

# ファイルアップロード
post '/bucket/:bucket_name/keys' do |bucket_name|
  @bucket = S3.bucket(bucket_name)
  thumbs_bucket = S3.bucket(bucket_name+'-thumb')
  file = params[:object]
  begin
    key = @bucket.put(file[:filename], file[:tempfile], {},
                      'public-read-write', {'content-type' => file[:type]})

    # サムネイル作成
    if file[:type] =~ %r!image/!
      image = MiniMagick::Image.open(file[:tempfile].path)
      image.resize '100x100'
      thumb = image.to_blob
      key = thumbs_bucket.put(file[:filename], thumb, {},
                        'public-read-write', {'content-type' => file[:type]})
    end
  rescue => e
    @errors = []
    @errors << e.message
  end

  @keys = @bucket.keys({}, true)
  @thumbs = get_thumbs(@keys, thumbs_bucket)
  haml :keys
end
