require File.dirname(__FILE__) + '/spec_helper'

describe AuditedRecord, "defining audit class properties", :type => :model do
  context "incorrectly" do
    it "fails if the association isn't specified" do
      lambda {
        ce { audits_attributes }
      }.should raise_exception
    end

    it "fails if the association parameter doesn't have a :through key" do
      lambda {
        ce { audits_attributes :bad_key => :foo }
      }.should raise_exception
    end

    it "fails if the association doesn't exist" do
      lambda {
        ce { audits_attributes :through => :bad_association }
      }.should raise_exception
    end
  end

  context "correctly" do
    it "succeeds if the :through parameter defines a valid association" do
      lambda {
        ce {
          has_many :audits
          audits_attributes :through => :audits
        }
      }.should_not raise_exception
    end
  end
end

