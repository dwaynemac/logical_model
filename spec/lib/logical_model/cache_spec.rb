require './lib/logical_model'

describe LogicalModel::Cache do
  describe "when included" do
    before do
      class Example
        include LogicalModel::RESTActions
        extend ActiveModel::Callbacks
        define_model_callbacks :create, :save, :update, :destroy, :initialize
        include LogicalModel::SafeLog
        include LogicalModel::Cache

        # include ActiveModel Modules that are usefull
        extend ActiveModel::Naming
        include ActiveModel::Conversion
        include ActiveModel::Serializers::JSON
        include ActiveModel::Validations
        include ActiveModel::MassAssignmentSecurity

      end
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
        #set value on cache
      end

      it "#async_find should return the cached value" do
        # Example.async_find("id") { |r| result = r}
        # result.should == cache
      end
    end

    describe "cached value not present" do
      before do
        #clear cache
      end

      it "#async_find should look for the value" do
        #async_find_without cache should be called
      end

      it "#async_find_response should store the value in the cache" do
        #async_find_without_cache should be called
      end
    end
  end
end
