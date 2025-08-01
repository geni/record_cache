require 'test_helper'

RecordCache::Set.source_tracking = true

class CreateTables < ActiveRecord::Migration[8.0]
  def self.up
    down
    create_table :pets do |t|
      t.column :breed_id, :bigint
      t.column :name, :string
      t.column :color_id, :bigint
      t.column :sex, :char
      t.column :type, :string
    end

    create_table :breeds do |t|
      t.column :name, :string
    end

    create_table :colors do |t|
      t.column :name, :string
    end
  end

  def self.down
    drop_table :pets   rescue nil
    drop_table :breeds rescue nil
    drop_table :colors rescue nil
  end
end

begin
  CacheVersionMigration.down
  CreateTables.down
rescue ActiveRecord::StatementInvalid
  # Ignore
end

CacheVersionMigration.up
CreateTables.up

class Pet < ActiveRecord::Base
  belongs_to :breed
  belongs_to :color

  record_cache :by => :id
  record_cache :id, :by => :breed_id
  record_cache :id, :by => :color_id, :write_ahead => true

  record_cache :id, :by => :color_id, :scope => {:sex => 'm'}, :prefix => 'male'
  record_cache :id, :by => :color_id, :scope => {:sex => 'f'}, :prefix => 'female'
  record_cache :id, :by => :color_id, :scope => {:sex => ['m','f']}, :name => 'all_colors'
end

class Dog < Pet
end

class Cat < Pet
end

class Breed < ActiveRecord::Base
end

class Color < ActiveRecord::Base
end

class RecordCacheTest < ActiveSupport::TestCase
  class << self
    attr_accessor :pitbull_retriever, :house_cat, :pitbull_terrier, :mutt
    attr_accessor :black_and_white, :speckled, :brown
  end

  def self.startup
    system('memcached -d')
  end

  def self.shutdown
    system('killall memcached')
    CacheVersionMigration.down
    CreateTables.down
  end

  def self.init_breeds
    self.pitbull_retriever = Breed.create(:name => 'pitbull retriever')
    self.house_cat = Breed.create(:name => 'house cat')
    self.pitbull_terrier = Breed.create(:name => 'pitbull terrier')
    self.mutt = Breed.create(:name => 'mutt')
  end

  def self.init_colors
    self.black_and_white = Color.create(:name => 'black & white')
    self.speckled = Color.create(:name => 'speckled')
    self.brown = Color.create(:name => 'brown')
  end

  def self.delete_all_models
    # Clean up database between tests
    [Dog, Cat, Pet, Breed, Color].each do |klass|
      klass.delete_all
    end
    CACHE.flush_all
  end

  setup do
    RecordCache::Index.enable_db
    RecordCacheTest.delete_all_models

    RecordCacheTest.init_breeds
    RecordCacheTest.init_colors
  end

  context "With a memcache and db connection" do
    should 'find_by_id with space' do
      dog = Dog.create(:name => 'Frankie')
      assert Pet.find_by_id("#{dog.id} ")
    end

    should 'create field lookup functions' do
      willy = Cat.create(:name => 'Willy', :breed => self.class.house_cat)
      milly = Dog.create(:name => 'Milly', :breed => self.class.pitbull_retriever)

      expected = {self.class.pitbull_retriever.id => milly.id, self.class.house_cat.id => willy.id}
      assert_equal expected, Pet.id_by_breed_id([self.class.pitbull_retriever.id, self.class.house_cat.id, 100, 101])
    end

    should 'return cached values without accessing the database' do
      daisy = Dog.create(:name => 'Daisy', :color => self.class.black_and_white, :breed => self.class.pitbull_retriever)
      willy = Cat.create(:name => 'Willy', :color => self.class.black_and_white, :breed => self.class.house_cat)

      Pet.find(daisy.id, willy.id)
      Dog.find_all_by_color_id(self.class.black_and_white.id)
      Dog.find_all_by_breed_id(self.class.pitbull_retriever.id)

      RecordCache::Index.disable_db

      assert_equal Dog,     Dog.find(daisy.id).class
      assert_equal daisy,   Dog.find(daisy.id)
      assert_equal Cat,     Cat.find(willy.id).class
      assert_equal willy,   Cat.find(willy.id)
      assert_equal [daisy], Dog.where(:color_id => self.class.black_and_white.id).all
      assert_equal [daisy], Dog.find_all_by_color_id(self.class.black_and_white.id)
      assert_equal [willy], Cat.find_all_by_color_id(self.class.black_and_white.id)
      assert_equal [willy], Cat.where(:color_id => self.class.black_and_white.id).all
      assert_equal [daisy], Dog.find_all_by_breed_id(self.class.pitbull_retriever.id)

      RecordCache::Index.enable_db

      assert_raises(ActiveRecord::RecordNotFound) do
        Dog.find(willy.id)
      end

      assert_raises(ActiveRecord::RecordNotFound) do
        Cat.find(daisy.id)
      end
    end

    should 'return multiple cached values without accessing the database' do
      winny = Dog.create(:name => 'Winny', :color => self.class.black_and_white, :breed => self.class.pitbull_retriever)
      sammy = Dog.create(:name => 'Sammy', :color => self.class.black_and_white, :breed => self.class.pitbull_terrier)

      Dog.find(winny.id, sammy.id)
      Dog.find_all_by_color_id(self.class.black_and_white.id)
      Dog.find_all_by_breed_id([self.class.pitbull_retriever.id, self.class.pitbull_terrier.id])

      RecordCache::Index.disable_db

      assert_equal [winny, sammy].to_set, Dog.find(winny.id, sammy.id).to_set
      assert_equal [winny, sammy].to_set, Dog.find_all_by_color_id(self.class.black_and_white.id).to_set
      assert_equal [winny, sammy].to_set, Dog.where(:color_id => self.class.black_and_white.id).all.to_set
      assert_equal [winny, sammy].to_set, Dog.find_all_by_breed_id([self.class.pitbull_retriever.id, self.class.pitbull_terrier.id]).to_set
      assert_equal [sammy, winny].to_set, Dog.find_all_by_breed_id([self.class.pitbull_terrier.id, self.class.pitbull_retriever.id]).to_set
      assert_equal [winny].to_set,        Dog.find_all_by_breed_id(self.class.pitbull_retriever.id).to_set

      # Alternate find methods.
      assert_equal [sammy.id, winny.id].to_set, Dog.find_ids_by_breed_id([self.class.pitbull_terrier.id, self.class.pitbull_retriever.id]).to_set

      assert_equal winny, Dog.find_by_color_id(self.class.black_and_white.id)
      assert_equal winny, Dog.find_by_breed_id([self.class.pitbull_retriever.id, self.class.pitbull_terrier.id])
      assert_equal sammy, Dog.find_by_breed_id([self.class.pitbull_terrier.id, self.class.pitbull_retriever.id])

      baseball = Dog.create(:name => 'Baseball', :color => self.class.speckled, :breed => self.class.pitbull_retriever)

      RecordCache::Index.enable_db

      assert_equal [winny, baseball], Dog.find_all_by_breed_id(self.class.pitbull_retriever.id)
      assert_equal [winny, baseball], Dog.where(["breed_id IN (?)", [self.class.pitbull_retriever.id]]).all
    end

    should 'create raw find methods' do
      sandy = Dog.create(:name => 'Sandy')
      sammy = Dog.create(:name => 'Sammy')

      Dog.find(sandy.id, sammy.id)
      RecordCache::Index.disable_db

      raw_records = Dog.find_raw_by_id([sammy.id, sandy.id])
      assert_equal ['Sammy', 'Sandy'], raw_records.collect {|r| r['name']}
    end

    should 'cache indexes using scope' do
      sunny = Dog.create(:name => 'Sunny', :color => self.class.black_and_white, :breed => self.class.pitbull_retriever, :sex => 'f')
      sammy = Dog.create(:name => 'Sammy', :color => self.class.black_and_white, :breed => self.class.pitbull_terrier, :sex => 'm')

      assert_equal [sammy],        Dog.find_all_male_by_color_id(self.class.black_and_white.id)
      assert_equal [sunny],        Dog.find_all_female_by_color_id(self.class.black_and_white.id)
      assert_equal [sunny, sammy], Dog.find_all_colors(self.class.black_and_white.id)

      cousin = Dog.create(:name => 'Cousin', :color => self.class.black_and_white, :breed => self.class.pitbull_terrier, :sex => 'm')

      assert_equal [sammy, cousin],        Dog.find_all_male_by_color_id(self.class.black_and_white.id)
      assert_equal [sunny, sammy, cousin], Dog.find_all_colors(self.class.black_and_white.id)
    end

    should 'yield cached indexes' do
      count = 0
      Dog.each_cached_index do |index|
        count += 1
      end
      assert_equal 6, count
    end

    should 'invalidate indexes on save' do
      millie = Dog.create(:name => 'Millie', :color => self.class.black_and_white, :breed => self.class.mutt, :sex => 'f')

      assert_equal millie, Dog.find_by_color_id(self.class.black_and_white.id)

      millie.name  = 'Molly'
      millie.color = self.class.brown
      millie.save

      assert_equal 'Molly', millie.name
      assert_equal self.class.brown.id, millie.color_id

      assert_equal millie, Dog.find_by_color_id(self.class.brown.id)
      assert_nil           Dog.find_by_color_id(self.class.black_and_white.id)
    end
  end
end
