require File.dirname(__FILE__) + '/../client'

# NOTE: to run these specs you must have the service running locally. Do like this:
# ruby service.rb -p 3000 -e test

# Also note that after a single run of the tests the server must be restarted to reset
# the database. We could change this by deleting all users in the test setup.
describe "LogicalModel User client" do

  describe "#create" do
    context "with valid attributes" do
      before(:each) do
        @user = User.new({:name => "paul", 
                          :email => "paul@pauldix.net", 
                          :password => "strongpass", 
                          :bio => "rubyist"})
        @user.create
      end
      it "should create a user" do
        @user.should_not be_nil
      end
      it "should set an id" do
        @user.id.should_not be_nil
      end
      it "should hace the same attributes as passed" do
        @user.name.should == "paul"
        @user.email == "paul@pauldix.net"
      end
    end
  end

  describe "#paginate" do
    before do
      # --> Mock service
      req = Typhoeus::Request.any_instance
      response = mock(
        code: 200,
        body: {
          collection: [{name:'a',email:'a@m'},
                       {name:'b',email:'b@m'},
                       {name:'c',email:'c@m'}],
          total: 6
        }.to_json,
        request: mock(url:"mockedurl"),
        time: 1234
      )
      req.stub(:on_complete).and_yield(response)
      # <-- service mocked

      @users = User.paginate(page:1, per_page:1)
    end
    it "should return a Kaminari::PaginatableArray" do
      @users.should be_a(Kaminari::PaginatableArray)
    end
    it "should set total_count" do
      @users.total_count.should == 6
    end
  end
  
  describe "#https" do
    context "when use_ssl is tue" do
      before(:each) do
        class User < LogicalModel;self.use_ssl = true;end
      end
      it "should use https://" do
        User.resource_uri.should match /https/
      end
    end
    context "when use_ssl is false" do
      before(:each) do
        class User < LogicalModel;self.use_ssl = false;end
      end
      it "should use http://" do
        User.resource_uri.should match /http/
        User.resource_uri.should_not match /https/
      end
    end
  end
end