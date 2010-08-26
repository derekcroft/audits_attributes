require File.dirname(__FILE__) + '/spec_helper'

describe AuditedRecord, "defining auditable events", :type => :model do
  before(:each) do
    ce {
      has_many :audits
      audits_attributes :through => :audits
    }
  end

  after(:each) do
    AuditedRecord.auditable_attributes = nil
  end

  context "correctly" do
    context "with message" do
      it "allows individual attributes to be audited with a message" do
        lambda {
          ce { attr_auditable :number_to_change, :message => "Number changed" }
        }.should_not raise_exception
      end

      it "allows multiple attributes to be audited with a message" do
        lambda {
          ce { attr_auditable :number_to_change, :date_to_change, :message => "Attribute changed" }
        }.should_not raise_exception
      end

      it "allows different messages for initially setting a value and changing it later" do
        lambda {
          ce { 
            attr_auditable :date_to_change, :message => {
              :initial => "Date To Change set",
              :changed => "Date To Change changed"
            }
          }
        }.should_not raise_exception
      end
    end

    it "allows the visibility of an attribute's audits to be public or internal" do
      lambda {
        ce { attr_auditable :number_to_change, :message => "Number changed", :visibility => "Public" }
      }.should_not raise_exception
    end

    it "appends newly-defined auditable attributes to a list" do
      AuditedRecord.should have(0).auditable_attributes
        
      ce { attr_auditable :number_to_change, :message => "Number changed" }
      AuditedRecord.should have(1).auditable_attributes

      ce { attr_auditable :date_to_change, :message => "Date changed" }
      AuditedRecord.should have(2).auditable_attributes
    end
  end

  context "incorrectly" do
    it "fails if attribute is defined as auditable without a message" do
      lambda {
        ce { attr_auditable :number_to_change }
      }.should raise_exception 
    end

    it "fails if specified attribute is not an attribute" do
      lambda {
        ce { attr_auditable :has_many, :message => "Invalid auditable." }
      }.should raise_exception
    end

    it "silently refuses to add a duplicate attribute to be audited" do
      AuditedRecord.should have(0).auditable_attributes
        
      ce { attr_auditable :number_to_change, :message => "Number changed" }
      AuditedRecord.should have(1).auditable_attributes

      ce { attr_auditable :number_to_change, :message => "Number changed" }
      AuditedRecord.should have(1).auditable_attributes
    end
  end
end
