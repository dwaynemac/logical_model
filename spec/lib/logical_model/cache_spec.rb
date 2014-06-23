require './lib/logical_model'

describe LogicalModel::Cache do
  class Example < LogicalModel
      
    attribute :id
    attribute :name
    
    self.hydra = Typhoeus::Hydra.new

    self.enable_delete_multiple = true
  end

  describe "when included" do
    before do
      
    end

    it "adds expires_in class method" do
      Example.should respond_to :expires_in
    end

    it "adds loaded_at as instance method" do
      Example.new.should respond_to :loaded_at
    end

    it "initializes loaded_at" do
      model = Example.new
      model.run_callbacks :initialize
      model.loaded_at.should_not be_nil
    end

    it "should use params to build cache_key" do
      cache_key = Example.cache_key('id', {})
      cache_key2 = Example.cache_key('id', {:param => true})
      cache_key.should_not == cache_key2
    end

    it "should chain find_async" do
      Example.should respond_to :async_find_with_cache
      Example.should respond_to :async_find_without_cache
    end

    describe "cached value present" do
      before do
        Example.stub_chain(:cache_store, :read).and_return("test")
      end

      it "#async_find should return the cached value" do
        Example.async_find("id") { |r| @result = r}
        @result.should == "test"
      end
    end

    describe "cached value not present" do
      before do
        Example.stub_chain(:cache_store, :read).and_return(nil)
        Example.stub_chain(:cache_store, :write).and_return(nil)
      end

      it "#async_find should look for the value" do
        Example.should_receive(:async_find_without_cache)
        Example.async_find("id") {|r| @result = r}
      end

      it "#async_find_response should store the value in the cache" do
        Example.should_receive(:async_find_response_without_cache)
        Example.async_find_response("id", {}, "test")
      end
    end

    describe "save" do
      before do
        Example.stub_chain(:cache_store, :read).and_return(Example.new)
        Example.stub_chain(:cache_store, :delete_matched).and_return(nil)
        Example.async_find("id") {|r| @result = r}
      end

      it "should clear cache" do
        Example.cache_store.should_receive(:delete_matched)
        @result.save
      end
    end

    describe "update" do
      before do
        Example.stub_chain(:cache_store, :read).and_return(Example.new)
        Example.stub_chain(:cache_store, :delete_matched).and_return(nil)
        Example.any_instance.stub(:_update_without_cache).and_return(true)
        Example.async_find("id") {|r| @result = r}
      end

      it "should clear cache" do
        @result.should_receive(:_update_without_cache)
        @result.update({:name => "test"}) 
      end
    end

    describe "destroy" do
      before do
        Example.stub_chain(:cache_store, :read).and_return(Example.new)
        Example.stub_chain(:cache_store, :delete_matched).and_return(nil)
        Example.async_find("id") {|r| @result = r}
      end

      it "should clear cache" do
        Example.cache_store.should_receive(:delete_matched)
        @result.destroy
      end
    end

    describe "delete" do
      before do
        Example.stub_chain(:cache_store, :read).and_return(Example.new)
        Example.stub_chain(:cache_store, :delete_matched).and_return(nil)
        Example.async_find("id") {|r| @result = r}
      end

      it "should clear cache" do
        Example.cache_store.should_receive(:delete_matched)
        Example.delete("id")
      end
    end

    describe "delete_multiple" do
      before do
        Example.stub_chain(:cache_store, :read).and_return(Example.new)
        Example.stub_chain(:cache_store, :delete_matched).and_return(nil)
        Example.async_find("id") {|r| @result = r}
      end

      it "should clear cache" do
        Example.cache_store.should_receive(:delete_matched)
        Example.delete_multiple(["id1","id2"])
      end
    end
  end

  describe "when using has_many & belongs_to" do

    class SecondaryExample < LogicalModel
      attribute :id

      self.hydra = Typhoeus::Hydra.new

      self.enable_delete_multiple = true

      belongs_to :example
    end

    class SecondaryExampleChild < SecondaryExample
      attribute :name
    end

    before do
      Example.has_many_keys = [:secondary_examples]
    end

    it "should set belongs_to_keys" do
      SecondaryExampleChild.belongs_to_keys.should_not be_blank
    end

    describe "save" do
      before do
        Example.stub_chain(:cache_store, :read).and_return(Example.new)
        SecondaryExampleChild.stub_chain(:cache_store, :read).and_return(SecondaryExampleChild.new(:example_id => 123))
        Example.stub_chain(:cache_store, :delete_matched).and_return(nil)
        SecondaryExampleChild.stub_chain(:cache_store, :delete_matched).and_return(nil)
        SecondaryExampleChild.async_find("id") {|r| @result = r}
      end

      it "should clear cache" do
        SecondaryExampleChild.cache_store.should_receive(:delete_matched).with(/example\/123-.*/)
        @result.save
      end
    end
  end
end
