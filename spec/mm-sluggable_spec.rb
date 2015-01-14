require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MongoMapper::Plugins::LearnupSluggable do

  before(:each) do
    @klass = article_class
  end

  describe "with defaults" do
    before(:each) do
      @klass.sluggable :title
      @article = @klass.new(:title => "testing 123")
    end

    it "should add a key called :slug" do
      @article.keys.keys.should include("slug")
    end

    it "should set the slug on validation" do
      lambda{
        @article.valid?
      }.should change(@article, :slug).from(nil).to("testing-123")
    end

    it "should add a version number starting at 2 if the slug conflicts" do
      @klass.create(:title => "testing 123")
      lambda{
        @article.valid?
      }.should change(@article, :slug).from(nil).to("testing-123-2")
    end

    it "should truncate slugs over the max_length default of 256 characters" do
      @article.title = "a" * 300
      @article.valid?
      @article.slug.length.should == 256
    end

    it "downcases slugs" do
      @article.title = "FOO"
      @article.valid?
      @article.slug.should == "foo"
    end
  end

  describe "with scope" do
    before(:each) do
      @klass.sluggable :title, :scope => :account_id
      @article = @klass.new(:title => "testing 123", :account_id => 1)
    end

    it "should add a version number if the slug conflics in the scope" do
      @klass.create(:title => "testing 123", :account_id => 1)
      lambda{
        @article.valid?
      }.should change(@article, :slug).from(nil).to("testing-123-2")
    end

    it "should not add a version number if the slug conflicts in a different scope" do
      @klass.create(:title => "testing 123", :account_id => 2)
      lambda{
        @article.valid?
      }.should change(@article, :slug).from(nil).to("testing-123")
    end
  end

  describe "with different key" do
    before(:each) do
      @klass.sluggable :title, :key => :title_slug
      @article = @klass.new(:title => "testing 123")
    end

    it "should add the specified key" do
      @article.keys.keys.should include("title_slug")
    end

    it "should set the slug on validation" do
      lambda{
        @article.valid?
      }.should change(@article, :title_slug).from(nil).to("testing-123")
    end
  end

  describe "with different slugging method" do
    before(:each) do
      @klass.sluggable :title, :method => :upcase
      @article = @klass.new(:title => "testing 123")
    end

    it "should set the slug using the specified method" do
      lambda{
        @article.valid?
      }.should change(@article, :slug).from(nil).to("TESTING 123")
    end
  end

  describe "with a different callback" do
    before(:each) do
      @klass.sluggable :title, :callback => :before_create
      @article = @klass.new(:title => "testing 123")
    end

    it "should not set the slug on the default callback" do
      lambda{
        @article.valid?
      }.should_not change(@article, :slug)
    end

    it "should set the slug on the specified callback" do
      lambda{
        @article.save
      }.should change(@article, :slug).from(nil).to("testing-123")
    end
  end

  describe "with custom max_length" do
    before(:each) do
      @klass.sluggable :title, :max_length => 5
      @article = @klass.new(:title => "testing 123")
    end

    it "should truncate slugs over the max length" do
      @article.valid?
      @article.slug.length.should == 5
    end
  end

  describe "with custom start" do
    before(:each) do
      @klass.sluggable :title, :start => 42
      @article = @klass.new(:title => "testing 123")
    end

    it "should start at the supplied version" do
      @klass.create(:title => "testing 123")
      lambda{
        @article.valid?
      }.should change(@article, :slug).from(nil).to("testing-123-42")
    end
  end

  describe "with SCI" do
    before do
      Animal = Class.new do
        include MongoMapper::Document
        key :name
      end
      Animal.collection.remove

      Dog = Class.new(Animal)
    end

    after do
      Object.send(:remove_const, :Animal)
      Object.send(:remove_const, :Dog)
    end

    describe "when defined in the base class" do
      before do
        Animal.instance_eval do
          plugin MongoMapper::Plugins::LearnupSluggable
          sluggable :name
        end
      end

      it "should scope it to the base class" do
        animal = Animal.new(:name => "rover")
        animal.save!
        animal.slug.should == "rover"

        dog = Dog.new(:name => "rover")
        dog.save!
        dog.slug.should == "rover-2"
      end
    end

    describe "when defined on the subclass" do
      before do
        Dog.instance_eval do
          plugin MongoMapper::Plugins::LearnupSluggable
          sluggable :name
        end
      end

      it "should scope it to the subclass" do
        animal = Animal.new(:name => "rover")
        animal.save!
        animal.should_not respond_to(:slug)

        dog = Dog.new(:name => "rover")
        dog.save!
        dog.slug.should == "rover"
      end
    end
  end

  describe "setting the slug on create" do
    before do
      @klass.sluggable :title
      @article = @klass.new
    end

    it "should use the slug assigned" do
      @article.title = "testing 123"
      @article.slug = "foobar"
      @article.save!

      @article.slug.should == "foobar"
    end

    it "should use the slug assigned (the other way around)" do
      @article.slug = "foobar"
      @article.title = "testing 123"
      @article.save!

      @article.slug.should == "foobar"
    end
  end

  describe "updating a slug (and keeping around old slugs)" do
    before do
      @employer_class = employer_class
      @employer = @employer_class.new(:title => "original")
      @employer.save!

      @old_slug = @employer.slug
    end

    it "should save the old slug in the old_slugs array" do
      @employer.slug = "foo-bar-baz"
      @employer.save!

      @employer.reload
      @employer.slug.should == 'foo-bar-baz'
      @employer.old_slugs.should == [@old_slug]
    end

    it "should remove a slug if it is the new slug" do
      @employer.slug = "foo-bar-baz"
      @employer.save!

      @employer.slug = @old_slug
      @employer.save!

      @employer.slug.should == @old_slug
      @employer.old_slugs.should == ["foo-bar-baz"]
    end

    it "should not add a slug to the old_slugs list twice" do
      @employer.slug = "one"
      @employer.save!

      @employer.slug = "two"
      @employer.save!

      @employer.slug = "one"
      @employer.save!

      @employer.slug = "two"
      @employer.save!

      @employer.old_slugs.should == [@old_slug, "one"]
    end
  end

  describe "find_by_slug" do
    before do
      @employer_class = employer_class
      @employer = @employer_class.new(:title => "original")
      @employer.save!

      @old_slug = @employer.slug
    end

    it "should find by slug" do
      @employer_class.find_by_slug(@employer.slug).should == @employer
    end

    it "should raise an OldSlugException if in the old slug list with the object + slug" do
      @employer.slug = "foo"
      @employer.save!

      expect {
        @employer_class.find_by_slug(@old_slug)
      }.to raise_error(MongoMapper::Plugins::LearnupSluggable::OldSlugException)

      begin
        @employer_class.find_by_slug(@old_slug)
      rescue => e
        e.object.should be_a_kind_of(@employer_class)
        e.new_slug.should == "foo"
        e.old_slug.should == @old_slug
      end
    end

    it "should raise an old slug exception if the case doesn't match (should it?)" do
      lambda {
        @employer_class.find_by_slug("ORIGINAL")
      }.should raise_error(MongoMapper::Plugins::LearnupSluggable::OldSlugException)
    end
  end

  describe "find_by_slug_or_id" do
    before do
      @employer_class = employer_class
      @employer = @employer_class.new(:title => "original")
      @employer.save!
    end

    it "should find an object by slug" do
      @employer_class.find_by_slug_or_id(@employer.slug).should == @employer
    end

    it "should find an object by id" do
      @employer_class.find_by_slug_or_id(@employer.id).should == @employer
    end

    it "should return nil if it cannot find the slug" do
      @employer_class.find_by_slug_or_id("foobar").should be_nil
    end
  end

  describe "find_by_slug_or_id!" do
    before do
      @employer_class = employer_class
      @employer = @employer_class.new(:title => "original")
      @employer.save!
    end

    it "should find an object by slug" do
      @employer_class.find_by_slug_or_id!(@employer.slug).should == @employer
    end

    it "should find an object by id" do
      @employer_class.find_by_slug_or_id!(@employer.id).should == @employer
    end

    it "should raise a MongoMapper::DocumentNotFound if it cannot find the slug" do
      lambda {
        @employer_class.find_by_slug_or_id!("foobar")
      }.should raise_error(MongoMapper::DocumentNotFound)
    end
  end

  describe "find_by_slug!" do
    before do
      @employer_class = employer_class
      @employer = @employer_class.new(:title => "original")
      @employer.save!
    end

    it "should find an object by slug" do
      @employer_class.find_by_slug!(@employer.slug).should == @employer
    end

    it "should raise a MongoMapper::DocumentNotFound if it cannot find the slug" do
      lambda {
        @employer_class.find_by_slug!("foobar")
      }.should raise_error(MongoMapper::DocumentNotFound)
    end
  end

  describe "to_param" do
    before do
      @employer_class = employer_class
      @employer = @employer_class.new(:title => "original")
      @employer.save!
    end

    it "should use the id if no slug is set" do
      @employer.slug = nil
      @employer.to_param.should == @employer.id.to_s
    end

    it "should use the slug" do
      @employer.to_param.should == @employer.slug
    end
  end

  describe "scoping" do
    before do
      @training_class = training_class
    end

    it "should scope a slug" do
      @training = @training_class.new({
        :job_title_id => 1,
        :title => "Foo"
      })
      @training.save!

      @training.slug.should == "foo"

      @training_two = @training_class.new({
        :job_title_id => 1,
        :title => "Foo"
      })
      @training_two.save!

      @training_two.slug.should == "foo-2"
    end

    it "should generate a new slug when the field changes and it scope it properly (if set to before_validation)" do
      @training = @training_class.new({
        :job_title_id => 1,
        :title => "Foo"
      })
      @training.save!

      @training.slug.should == "foo"

      @training_two = @training_class.new({
        :job_title_id => 1,
        :title => "Bar"
      })
      @training_two.save!

      @training_two.slug.should == "bar"

      # now change it
      @training_two.title = "Foo"
      @training_two.save!
      @training_two.slug.should == "foo-2"
    end
  end
end