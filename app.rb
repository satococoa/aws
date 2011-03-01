# coding: utf-8
configure do
  config = YAML::load_file('config.yml')
  ACCESS = config['aws']['access']
  SECRET = config['aws']['secret']

  S3 = RightAws::S3.new(ACCESS, SECRET, :server => 's3-ap-southeast-1.amazonaws.com')
  CF = RightAws::AcfInterface.new(ACCESS, SECRET)
end

helpers do
  def number_format(val)
    val.to_s.gsub(/(.*\d)(\d\d\d)/, '\1,\2')
  end
  def get_thumbs(keys, bucket)
    thumbs = {}
    keys.each do |key|
      if !bucket.nil? && bucket.key(key.name).exists?
        # thumbs[key.name] = bucket.key(key.name).public_link
        thumbs[key.name] = bucket.key(key.name)
      else
        # thumbs[key.name] = key.public_link
        thumbs[key.name] = key
      end
    end
    thumbs
  end
  def get_domain_for_bucket(bucket)
    "#{bucket.name}.s3.amazonaws.com"
  end
  def get_distribution_for_bucket(bucket, dists)
    dists.detect{|dist| dist[:origin] =~ /#{bucket.name}.+/}
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
    CF.create_distribution(get_domain_for_bucket(bucket), "distribution for #{bucket.name}")
    # サムネイル用
    thumbs_bucket = S3.bucket(params[:bucket]+'-thumb', true, nil, :location => 'ap-southeast-1')
    CF.create_distribution(get_domain_for_bucket(thumbs_bucket), "distribution for #{thumbs_bucket.name}")
  rescue RightAws::AwsError => e
    @errors = []
    @errors << e.message
  end
  @buckets = S3.buckets
  haml :buckets
end

# keyの一覧
get '/bucket/:bucket_name/keys' do |bucket_name|
  @bucket       = S3.bucket(bucket_name)
  thumbs_bucket = S3.bucket(bucket_name+'-thumb')
  dists         = CF.list_distributions
  @dist         = get_distribution_for_bucket(@bucket, dists)
  @thumbs_dist  = get_distribution_for_bucket(thumbs_bucket, dists)

  @keys   = @bucket.keys({}, true)
  @thumbs = get_thumbs(@keys, thumbs_bucket)

  haml :keys
end

# ファイルアップロード
post '/bucket/:bucket_name/keys' do |bucket_name|
  file = params[:object]

  @bucket       = S3.bucket(bucket_name)
  thumbs_bucket = S3.bucket(bucket_name+'-thumb')
  dists         = CF.list_distributions
  @dist         = get_distribution_for_bucket(@bucket, dists)
  @thumbs_dist  = get_distribution_for_bucket(thumbs_bucket, dists)

  begin
    key = @bucket.put(file[:filename], file[:tempfile], {},
                      'public-read-write', {'content-type' => file[:type]})

    # サムネイル作成
    if file[:type] =~ %r!image/!
      image = MiniMagick::Image.open(file[:tempfile].path)
      image.resize '100x100'
      thumb = image.to_blob
      key   = thumbs_bucket.put(file[:filename], thumb, {},
                        'public-read-write', {'content-type' => file[:type]})
    end
  rescue => e
    @errors = []
    @errors << e.message
  end

  @keys   = @bucket.keys({}, true)
  @thumbs = get_thumbs(@keys, thumbs_bucket)
  haml :keys
end
