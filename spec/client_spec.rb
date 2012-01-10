require File.dirname(__FILE__) + '/../client'

require File.dirname(__FILE__) + '/../test/typhoeus_mocks.rb'
include TyphoeusMocks

# NOTE: to run these specs you must have the service running locally. Do like this:
# ruby service.rb -p 3000 -e test

# Also note that after a single run of the tests the server must be restarted to reset
# the database. We could change this by deleting all users in the test setup.
describe "LogicalModel User client" do

  describe "#create" do
    context "with valid attributes" do
      before(:each) do
        # TODO mock service
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
      mock_index(
        collection: [{name:'a',email:'a@m'},
                     {name:'b',email:'b@m'},
                     {name:'c',email:'c@m'}],
        total: 6
      )

      @users = User.paginate(page:1, per_page:1)
    end
    it "should return a Kaminari::PaginatableArray" do
      @users.should be_a(Kaminari::PaginatableArray)
    end
    it "should set total_count" do
      @users.total_count.should == 6
    end
  end

  describe "#count" do
    before do
      mock_index(
        total: 6
      )
    end
    let(:count){User.count}
    it "should return a Integer" do
      count.should be_a(Integer)
    end
    it "should return total amount of users" do
      count.should == 6
    end
  end

  describe "#find" do
    context "if found" do
      before do
        mock_show(
          attributes: {
            id: 1,
            name: 'mocked-username',
            email: 'mocked@mail',
            password: '1234',
            bio: 'asdfasdf'
          }
        )

        @user = User.find(1)
      end
      it "should set attributes" do
        @user.id.should == 1
        @user.email.should == "mocked@mail"
      end
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