require File.dirname(__FILE__) + '/spec_helper'

class QuickAudit < ActiveRecord::Base; end

describe AuditedRecord, "defining and applying quick audits", :type => :model do
  context "defining quick audit model" do
    before(:each) do
      ce {
        has_many :audits
      }
    end

    it "allows user to define the model that has quick audits" do
      lambda {
        ce { audits_attributes :through => :audits, :quick_audit_model => QuickAudit }
      }.should_not raise_exception
    end

    it "rejects the quick audit model if it doesn't exist" do
      lambda {
        ce { audits_attributes :through => :audits, :quick_audit_model => QuickAuditNonexistent }
      }.should raise_exception
    end
  end

  context "applying quick audits" do
    before(:each) do
      ce {
        has_many :audits
        audits_attributes :through => :audits, :quick_audit_model => QuickAudit 
      }
      @ar = AuditedRecord.create({ :number_to_change => 1 })
    end

    it "allows user to apply a quick audit by ID" do
      id = QuickAudit.create( {
        :description => "Quick audit",
        :visibility => "Public"
      } )[:id]
      
      lambda {
        @ar.quick_audit(id)
      }.should change(@ar.audits, :count).by(1)
      @ar.audits.last.description.should == "Quick audit"
      @ar.audits.last.visibility.should == "Public"
    end
  end
end
