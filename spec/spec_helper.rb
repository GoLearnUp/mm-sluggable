$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'
require 'simplecov'
SimpleCov.start if ENV['COVERAGE'] == '1'
require 'mm-learnup-sluggable'

MongoMapper.database = 'mm-learnup-sluggable-spec'

def article_class
  Class.new do
    include MongoMapper::Document
    set_collection_name :articles

    plugin MongoMapper::Plugins::LearnupSluggable

    key :title,       String
    key :account_id,  Integer
  end
end

def employer_class
  Class.new do
    include MongoMapper::Document
    set_collection_name :employers

    plugin MongoMapper::Plugins::LearnupSluggable

    key :title,       String
    sluggable :title
  end
end

def training_class
  Class.new do
    include MongoMapper::Document
    set_collection_name :trainings

    plugin MongoMapper::Plugins::LearnupSluggable

    key :title,       String
    key :job_title_id, Integer
    sluggable :title, :scope => :job_title_id, :callback => :before_validation
  end
end

RSpec.configure do |config|
  def wipe_db
    MongoMapper.database.collections.each do |c|
      unless (c.name =~ /system/)
        c.remove
      end
    end
  end

  config.before(:each) do
    wipe_db
  end
end
