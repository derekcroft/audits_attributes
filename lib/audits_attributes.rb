# AuditsAttributes
module AuditsAttributes
  def self.included(base)
    base.send :extend, ClassMethods 

    Class.new(ActiveRecord::Observer) do
      observe base
      def after_update(record)
        record.audit_changed_attributes if record.changed?
      end

      def after_create(record)
        record.audit_creation
      end
    end.instance
  end

  module ClassMethods
    def auditable_attributes
      @@auditable_attributes ||= {} 
      @@auditable_attributes
    end

    def auditable_attributes=(val)
      @@auditable_attributes = val
    end

    def audit_through
      @@audit_through
    end

    def audit_through=(val)
      @@audit_through = val
    end

    def quick_audit_model
      @@quick_audit_model
    end

    def quick_audit_model=(val)
      @@quick_audit_model = val
    end

    def audits_attributes(hash)
      raise ArgumentError, 'audits_attributes must have a :through parameter.' unless hash.include? :through 

      self.audit_through = hash[:through]
      self.quick_audit_model = hash[:quick_audit_model]

      raise ArgumentError, "audits_attributes :through parameter must point to a valid association." unless self.reflect_on_association(hash[:through])

      send :include, InstanceMethods
    end

    def attr_auditable(*attr)
      hashes, attrs = attr.partition { |a| a.is_a? Hash }
      raise ArgumentError, "attr_auditable has to have a :message parameter" if hashes.empty? or !hashes.first.include? :message

      invalid_attrs = attrs.find_all do |a| 
        !self.columns_hash[a.to_s]
      end
      raise ArgumentError, "invalid attributes passed to attr_auditable: #{invalid_attrs.join(",")}" unless invalid_attrs.empty?

      attrs.each do |a|
        self.auditable_attributes[a] = hashes.first
      end
    end

  end

  module InstanceMethods
    def audit_changed_attributes
      self.changes.each do |key, value| 
        att = self.class.auditable_attributes[key.to_sym]
        generate_audit(att, value) if att
      end             
    end

    def audit_creation
      generate_audit( {
        :message => "#{self.class.human_name.capitalize} Created",
        :visibility => "Public"
      } )
    end

    def quick_audit(id)
      raise ArgumentError, "#{self.class.human_name} must have :quick_audit_model defined before quick audits can be applied to it." unless self.class.quick_audit_model

      quick_audit = self.class.quick_audit_model.find(id)
      generate_audit( {
        :message => quick_audit.description,
        :visibility => quick_audit.visibility 
      } ) 
    end
 
    protected 
    def generate_audit(attr, change=[nil, nil])
      self.send(self.class.audit_through).create({
        :description => replaced_message(attr[:message], change),
        :initial_value => change.first,
        :changed_value => change.last,
        :changed_by => ((User.current_user and User.current_user.id) || nil),
        :visibility => attr[:visibility] || "Internal"
      })
    end

    private
    def replaced_message(message, change)
      proper_message(message, change).
        gsub(/\{initial_value\}/, string_from(change.first)).
        gsub(/\{changed_value\}/, string_from(change.last))
    end

    def string_from(value)
      value.respond_to?(:strftime) ? value.strftime("%m/%d/%Y") : value.to_s
    end

    def proper_message(message, change)
      return message unless message.is_a? Hash
      change.first.nil? ?
        message[:initial] : message[:changed]
    end
  end
end
