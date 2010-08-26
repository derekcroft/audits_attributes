require File.dirname(__FILE__) + '/spec_helper'

describe AuditedRecord, "generating audits", :type => :model do
  before(:each) do
    ce {
      has_many :audits
      audits_attributes :through => :audits
      attr_auditable :number_to_change, :message => "Number changed"
    }
    @ar = AuditedRecord.create({ :number_to_change => 1 })
  end

  context "on callbacks" do
    it "generates an audit when a record is created" do
      @ar.should have(1).audit 
      @ar.audits.last.description.should =~ /Created/
    end
  end

  context "on changes" do
    it "audits changed attributes when a record is saved" do
      @ar.should_receive(:audit_changed_attributes)
      @ar.update_attribute(:number_to_change, 2)
    end

    it "generates an audit when one of the specified attributes changes" do
      lambda {
        @ar.update_attribute(:number_to_change, 2)
      }.should change(@ar.audits, :count).by(1)
    end
  end

  context "with messages" do
    it "generates audits with the proper message" do
      @ar.update_attribute(:number_to_change, 2) 
      @ar.audits.last.description.should == "Number changed"
    end

    it "replaces placeholders in a message with the proper values" do
      ce {
        attr_auditable :number_to_change, :message => {
          :initial => "Number set to {changed_value}",
          :changed => "Number changed from {initial_value} to {changed_value}"
        }
      }
      @ar = AuditedRecord.create
      @ar.update_attribute(:number_to_change, 4)
      @ar.audits.last.description.should == "Number set to 4" 

      @ar.update_attribute(:number_to_change, 5)
      @ar.audits.last.description.should == "Number changed from 4 to 5"
    end

    context "with different messages for creation and updating" do
      before(:each) do
        ce { 
          attr_auditable :date_to_change, :message => {
            :initial => "Date To Change set",
            :changed => "Date To Change changed"
          }
        }
      end

      it "generates a message for the initial value of attribute" do
        @ar.update_attribute(:date_to_change, Date.new)
        @ar.audits.last.description.should == "Date To Change set" 
      end

      it "generates a message when an attribute is changed" do
        @ar.update_attribute(:date_to_change, Date.new)
        @ar.update_attribute(:date_to_change, Date.new+1)
        @ar.audits.last.description.should == "Date To Change changed" 
      end
    end
  end

  context "with the proper attributes" do
    it "generates audits for the correct user" do
      User.should_receive(:current_user)
      @ar.update_attribute(:number_to_change, 2)
    end

    it "generates audits with internal visibility if none is specified" do
      @ar.update_attribute(:number_to_change, 2)
      @ar.audits.last.visibility.should == "Internal" 
    end

    it "generates audits with the specified visibility if one is specified" do  
      ce {
        attr_auditable :date_to_change, :message => "Date changed", :visibility => "Public"
      }
      @ar = AuditedRecord.create({ :date_to_change => Date.new })
      @ar.update_attribute(:date_to_change, Date.new+1)
      @ar.audits.last.visibility.should == "Public"
    end
  end
end
