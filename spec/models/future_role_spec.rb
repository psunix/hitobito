# frozen_string_literal: true
#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require 'spec_helper'

describe FutureRole do
  let(:person) { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }
  let(:role_type) { Group::TopGroup::Member.sti_name }
  let(:tomorrow) { Time.zone.tomorrow }

  def build(attrs = {})
    defaults = { person: person, group: top_group, convert_to: role_type, convert_on: tomorrow }
    Fabricate.build(:future_role, defaults.merge(attrs))
  end

  describe 'validations' do
    it 'fabrication builds valid model' do
      expect(build).to be_valid
    end

    it 'is invalid with blank person or group' do
      expect(build(person: nil)).to have(1).error_on(:person)
      expect(build(group: nil)).to have(1).error_on(:group)
    end

    it 'validates that convert_on is present and not in the past' do
      expect(build(convert_on: nil)).to have(1).error_on(:convert_on)
      expect(build(convert_on: Time.zone.yesterday)).to have(1).error_on(:convert_on)
      expect(build(convert_on: Time.zone.today)).to be_valid
    end

    it 'validates that convert_to is present and of type supported by group' do
      expect(build(convert_to: nil)).to have(1).error_on(:convert_to)
      expect(build(convert_to: Group::TopLayer::TopAdmin.sti_name)).to have(1).error_on(:convert_to)
      expect(build(convert_to: Group::TopGroup::Leader.sti_name)).to be_valid
    end
  end

  describe 'callbacks' do
    it 'skips create callbacks' do
      role = build
      expect(role).not_to receive(:set_contact_data_visible)
      expect(role).not_to receive(:set_first_primary_group)
      role.save!
    end

    it 'skips destroy callbacks' do
      role = build.tap(&:save!)
      expect(role).not_to receive(:reset_contact_data_visible)
      expect(role).not_to receive(:reset_primary_group)
      role.destroy!
    end
  end

  describe '#to_s' do
    it 'includes starting date' do
      travel_to(Time.zone.local(2023, 11, 3, 14)) do
        expect(build.to_s).to eq 'Member (ab 04.11.2023)'
      end
    end
  end

  describe '#convert!' do
    it 'really_destroys self and creates new role with same attributes' do
      attrs = { created_at: 10.days.ago.noon, delete_on: 10.days.from_now.noon, label: 'test' }
      role = build(attrs).tap(&:save!)
      expect { role.convert! }.not_to change { Role.unscoped.count }
      expect(person.roles.where(attrs.except(:created_at).merge(type: role_type))).to be_exist
    end
  end
end
