class Participant < ActiveRecord::Base
  belongs_to :partable, :polymorphic => true
  belongs_to :user

  validates_presence_of :user
  validates_uniqueness_of :user_id, :scope => [:partable_type, :partable_id]
  validate :validate_user

  ROLES = [:leader, :requester, :resolver, :tester, :tracker]

  def roles_description
    roles = []
    roles.push(l(:label_participant_type_leader)) if self.is_leader
    roles.push(l(:label_participant_type_requester)) if self.is_requester
    roles.push(l(:label_participant_type_resolver)) if self.is_resolver
    roles.push(l(:label_participant_type_tester)) if self.is_tester
    roles.push(l(:label_participant_type_tracker)) if self.is_tracker
    roles.join(", ")
  end

  # Participant.update(issue, {:user_id => 1, :roles => :is_requester, :checked => true})
  def self.update(partable, opts = {})
    checked = opts[:checked]
    user_id = opts[:user_id]
    scope = partable.participants.where(:user_id => user_id)
    participant = scope.first()
    roles = Array.wrap(opts[:roles]).map(&:to_sym)

    if participant
      roles.each do |role|
        participant.update_attribute(role, checked)
      end
    else
      if checked
        participant = scope.new

        roles.each do |role|
          participant.write_attribute(role, checked)
        end

        participant.save!
      end
    end

    if participant
      if participant.is_leader ||
        participant.is_requester ||
        participant.is_resolver ||
        participant.is_tester ||
        participant.is_tracker
        participant
      else
        participant.destroy
      end
    end
  end

  protected

  def validate_user
    errors.add :user_id, :invalid unless user.nil? || user.active?
  end
end
