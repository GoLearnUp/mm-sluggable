$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'

require 'mm-sluggable'

MongoMapper.database = 'mm-sluggable-spec'

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
