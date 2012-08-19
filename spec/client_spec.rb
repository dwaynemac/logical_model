require File.dirname(__FILE__) + '/../client'

require File.dirname(__FILE__) + '/../test/typhoeus_mocks.rb'
include TyphoeusMocks

describe "LogicalModel User client" do

  describe "#create" do
    context "with valid attributes" do
      before(:each) do
        mock_post_with(code: 201, body: {'id' => 3}.to_json)
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
    context "when successfull" do
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
    context "when it fails" do
      before do
        req = Typhoeus::Request.any_instance
        response = mock( code: 500, body: "error", request: "mockedurl", time: 1234 )
        req.stub(:on_complete).and_yield(response)
      end
      it "should retry LogicalModel#retries times (default: 3)" do
        User.retries= 2
        LogicalModel.should_receive(:async_paginate).exactly(2)
        User.paginate(page:1,per_page:1).should be_nil
      end
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

  describe "use_api_key" do
    context "when true" do
      before(:each) do
        class User < LogicalModel; self.use_api_key=true; self.api_key_name='keyname'; self.api_key="secret_api_key"; end
      end
      it "should send api key in requests" do
        Typhoeus::Request.should_receive(:new).with(User.resource_uri(1),{:params=>{'keyname'=>'secret_api_key'}})
        begin
          User.find(1)
        rescue
        end
      end
      it "should mask api key in logs" do
        response = mock(
            code: 200,
            body: {}.to_json,
            request: mock(url: "server?keyname=secret_api_key"),
            time: 1234
        )
        Logger.any_instance.should_receive(:info).with(/\[SECRET\]/)
        User.log_ok(response)
        Logger.any_instance.should_receive(:warn).with(/\[SECRET\]/)
        User.log_failed(response)
      end
    end
    context "when false" do
      before(:each) do
        class User < LogicalModel; self.use_api_key=false; self.api_key_name='keyname'; self.api_key="secret_api_key"; end
      end
      it "should not send api key in requests" do
        Typhoeus::Request.should_not_receive(:new).with(User.resource_uri(1),{:params=>{'keyname'=>'secret_api_key'}})
        begin
          User.find(1)
        rescue
        end
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

  describe "delete_multiple" do
    before do
      Typhoeus::Request.stub!(:delete).and_return(mock_response(body: 'ok'))
    end
    context "when disabled" do
      it "should raise exception" do
        class User < LogicalModel; self.enable_delete_multiple = false; end
        expect{User.delete_multiple([1,2,4,5])}.to raise_error
      end
    end
    context "when enabled" do
      it "should raise exception" do
        class User < LogicalModel; self.enable_delete_multiple = true; end
        expect{User.delete_multiple([1,2,4,5])}.not_to raise_error
      end
    end
  end

  describe "#delete_multiple_enabled?" do
    context "with config: 'enable_multiple_delete = true'" do
      before do
        class User < LogicalModel
          self.enable_delete_multiple = true
        end
      end
      it "should return true" do
        User.delete_multiple_enabled?.should be_true
      end
    end
    context "with config: 'enable_delete_multiple = false'" do
        it "should return false" do
        class User < LogicalModel
          self.enable_delete_multiple = false
        end
        User.delete_multiple_enabled?.should be_false
      end
    end
    context "without config" do
      it "should default to false" do
        class AnotherClass < LogicalModel
        end
        AnotherClass.delete_multiple_enabled?.should be_false
      end
    end
  end

  describe "callbacks" do
    describe "before_save" do
      before do
        class User < LogicalModel
          before_save :raise_message

          def raise_message
            raise 'before_save_called'
          end
        end
      end
      it "should be called on #save" do
        u = User.new
        expect{u.save}.to raise_error('before_save_called')
      end
      it "should be called on #create" do
        u = User.new
        expect{u.create}.to raise_error('before_save_called')
      end
      it "should be called on #update" do
        u = User.new
        expect{u.update(id: 1)}.to raise_error('before_save_called')
      end
    end
    describe "before_destroy" do
      before do
        class User < LogicalModel
          before_destroy :raise_message

          def raise_message
            raise 'before_destroy_called'
          end
        end
      end
      it "should not be called on User.delete" do
        expect{User.delete(1)}.not_to raise_error('before_destroy_called')
      end
      it "should be called on #destroy" do
        u = User.new
        expect{u.destroy}.to raise_error('before_destroy_called')
      end
    end
  end

end