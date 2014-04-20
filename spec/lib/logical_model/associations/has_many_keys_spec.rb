require './lib/logical_model/associations/has_many_keys.rb'

describe LogicalModel::Associations::HasManyKeys do

  describe "when included" do
    before do
      class Example
        include LogicalModel::Associations::HasManyKeys
      end
    end

    it "adds has_many class method" do
      Example.should respond_to :has_many
    end
  end

  describe ".has_many" do
    before do
      # has_many :items needs Item class
      class Item
        attr_accessor :example_id
        attr_accessor :name
        def initialize(attrs={})
          @example_id = attrs['example_id']
          @name = attrs['name']
        end
      end

      class Example
        include LogicalModel::Associations::HasManyKeys
        has_many :items

        def initialize(atrs={})
          self.items = atrs[:items] if atrs[:items]
        end

        def json_root
          'example'
        end

        def id
          '234'
        end
      end
    end

    describe "adds #association= setter" do
      it "visible at instance" do
        e = Example.new
        e.should respond_to 'items='
      end

      it "wich accepts attributes" do
        e = Example.new
        e.items= [{'name' => 'bob'}]
        e.items.first.name.should == 'bob'
      end

      it "with accepts objects" do
        res = [Item.new]
        e = Example.new
        e.items= res
        e.items.should == res
      end

    end

    describe "adds #association accessor" do
      before do
        debugger
        @e = Example.new(items: [Item.new()])
      end
      it "visible at instance" do
        @e.should respond_to :items
      end

      it "wich returns array of objects" do
        @e.items.should be_a Array
        @e.items.first.should be_a Item
      end
    end

    describe "adds #new_xxx method" do
      it "allow initializing new objects of association" do
        e = Example.new
        i = e.new_item( {} )
        i.should be_a Item
      end

      it "initializes objects with parents id" do
        e = Example.new
        i = e.new_item( {} )
        i.example_id.should == e.id
      end
    end

  end
end
