require './lib/logical_model'

describe LogicalModel::Associations::HasManyKeys do

  describe "when included" do
    before do
      class Example < LogicalModel
      end
    end

    it "adds has_many class method" do
      Example.should respond_to :has_many
    end
  end

  describe ".has_many" do
    before do
      # has_many :items needs Item class
      class Item < LogicalModel
        attribute :name
        belongs_to :example
      end

      class SpecialItem < LogicalModel
        attribute :special_attribute
        belongs_to :example
      end

      class Example < LogicalModel
        has_many :items

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

    describe "when I initialize the has_many item using an extended class it should create the element using the correct class" do
      it "should build has_many correctly" do
        @example = Example.new({:items_attributes => [{"_type"=>"SpecialItem", "special_attribute"=>"test", "value"=>"123"}]})
        @example.items.first.class.should == SpecialItem
      end
    end

  end
end
