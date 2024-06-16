require 'rails_helper'

describe Story do
  subject { build :story, :with_project }
  before do
    subject.acting_user = build(:user)
  end

  describe 'validations' do
    describe '#title' do
      it 'is required' do
        subject.title = ''
        subject.valid?
        expect(subject.errors[:title].size).to eq(1)
      end
    end

    describe '#story_type' do
      it { is_expected.to validate_presence_of(:story_type) }
      it { is_expected.to enumerize(:story_type).in('feature', 'chore', 'bug', 'release') }
    end

    describe '#state' do
      it 'must be a valid state' do
        subject.state = 'flum'
        subject.valid?
        expect(subject.errors[:state].size).to eq(1)
      end
    end

    describe '#project' do
      it 'cannot be nil' do
        subject.project_id = nil
        subject.valid?
        expect(subject.errors[:project].size).to eq(1)
      end

      it 'must have a valid project_id' do
        subject.project_id = 'invalid'
        subject.valid?
        expect(subject.errors[:project].size).to eq(1)
      end

      it 'must have a project' do
        subject.project = nil
        subject.valid?
        expect(subject.errors[:project].size).to eq(1)
      end
    end

    describe '#estimate' do
      before do
        subject.project.users = [subject.requested_by]
      end

      it 'must be valid for the project point scale' do
        subject.project.point_scale = 'fibonacci'
        subject.estimate = 4 # not in the fibonacci series
        subject.valid?
        expect(subject.errors[:estimate].size).to eq(1)
      end

      context 'when try to estimate' do
        %w[chore bug release].each do |type|
          context "a #{type} story" do
            before { subject.attributes = { story_type: type, estimate: 1 } }

            it { is_expected.to be_invalid }
          end
        end

        context 'a feature story' do
          before { subject.attributes = { story_type: 'feature', estimate: 1 } }

          it { is_expected.to be_valid }
        end
      end
    end

    it { is_expected.to accept_nested_attributes_for(:tasks) }
    it { is_expected.to accept_nested_attributes_for(:comments) }
  end

  describe 'associations' do
    describe 'comments' do
      let!(:user) { create :user }
      let!(:project) { create :project, users: [user] }
      let!(:story) { create :story, project: project, requested_by: user }
      let!(:comment) { create(:comment, created_at: 2.days.from_now, user: user, story: story) }
      let!(:comment2) { create(:comment, created_at: Time.zone.today, user: user, story: story) }

      it 'order by created at' do
        story.reload

        expect(story.comments).to eq [comment2, comment]
      end
    end
  end

  describe '#to_s' do
    before { subject.title = 'Dummy Title' }
    its(:to_s) { should == 'Dummy Title' }
  end

  describe '#estimated?' do
    context 'when the story estimation is nil' do
      before { subject.estimate = nil }

      it { is_expected.not_to be_estimated }
    end

    context 'when the story estimation is 1' do
      before { subject.estimate = 1 }

      it { is_expected.to be_estimated }
    end
  end

  describe '#estimable_type?' do
    %w[chore bug release].each do |type|
      context "when is a #{type} story" do
        before { subject.story_type = type }

        it { is_expected.not_to be_estimable_type }
      end
    end

    context 'when is a feature story' do
      before { subject.story_type = 'feature' }

      it { is_expected.to be_estimable_type }
    end
  end

  describe '#accepted_at' do
    context 'when not set' do
      before { subject.accepted_at = nil }

      # FIXME: This is non-deterministic
      it "gets set when state changes to 'accepted'" do
        Timecop.freeze(Time.zone.parse('2016-08-31 12:00:00')) do
          subject.started_at = 5.days.ago
          subject.update_attribute :state, 'accepted'
          expect(subject.accepted_at).to eq(Time.current)
          expect(subject.cycle_time_in(:days)).to eq(5)
        end
      end
    end

    context 'when set' do
      before { subject.accepted_at = Time.zone.parse('1999/01/01') }

      # FIXME: This is non-deterministic
      it "is unchanged when state changes to 'accepted'" do
        subject.update_attribute :state, 'accepted'
        expect(subject.accepted_at).to eq(Time.zone.parse('1999/01/01'))
      end
    end
  end

  describe '#delivered_at' do
    context 'when not set' do
      before { subject.delivered_at = nil }

      it 'gets set when state changes to delivered_at' do
        Timecop.freeze(Time.zone.parse('2016-08-31 12:00:00')) do
          subject.update_attribute :state, 'delivered'
          expect(subject.delivered_at).to eq(Time.current)
        end
      end
    end

    context 'when there is already a delivered_at' do
      before { subject.delivered_at = Time.zone.parse('1999/01/01') }

      it 'is unchanged' do
        subject.update_attribute :state, 'delivered'
        expect(subject.delivered_at).to eq(Time.zone.parse('1999/01/01'))
      end
    end

    context 'when state does not change' do
      before { subject.delivered_at = nil }

      it 'delivered_at is not filled' do
        subject.update_attribute :title, 'New title'
        expect(subject.delivered_at).to eq(nil)
      end
    end
  end

  describe '#started_at' do
    context 'when not set' do
      before do
        subject.started_at = subject.owned_by = nil
      end

      # FIXME: This is non-deterministic
      it "gets set when state changes to 'started'" do
        Timecop.freeze(Time.zone.parse('2016-08-31 12:00:00')) do
          subject.update_attribute :state, 'started'
          expect(subject.started_at).to eq(Time.current)
          expect(subject.owned_by).to eq(subject.acting_user)
        end
      end
    end

    context 'when set' do
      before { subject.started_at = Time.zone.parse('2016-09-01 13:00:00') }

      # FIXME: This is non-deterministic
      it "is unchanged when state changes to 'started'" do
        subject.update_attribute :state, 'started'
        expect(subject.started_at).to eq(Time.zone.parse('2016-09-01 13:00:00'))
        expect(subject.owned_by).to eq(subject.acting_user)
      end
    end
  end

  describe '#stakeholders_users' do
    let(:requested_by)  { mock_model(User) }
    let(:owned_by)      { mock_model(User) }
    let(:comment_user)  { mock_model(User) }
    let(:comments)      { [build_stubbed(:comment, user: comment_user)] }

    before do
      subject.requested_by  = requested_by
      subject.owned_by      = owned_by
      subject.comments      = comments
    end

    specify do
      expect(subject.stakeholders_users).to include(requested_by)
    end

    specify do
      expect(subject.stakeholders_users).to include(owned_by)
    end

    specify do
      expect(subject.stakeholders_users).to include(comment_user)
    end

    it 'strips out nil values' do
      subject.requested_by = subject.owned_by = nil
      expect(subject.stakeholders_users).not_to include(nil)
    end
  end

  context 'when unscheduled' do
    before { subject.state = 'unscheduled' }
    its(:events)  { should == [:start] }
    its(:column)  { should == '#icebox' }
  end

  context 'when unstarted' do
    before { subject.state = 'unstarted' }
    its(:events)  { should == [:start] }
    its(:column)  { should == '#unstarted' }
  end

  context 'when started' do
    before { subject.state = 'started' }
    its(:events)  { should == [:finish] }
    its(:column)  { should == '#todo' }
  end

  context 'when finished' do
    before { subject.state = 'finished' }
    its(:events)  { should == [:deliver] }
    its(:column)  { should == '#todo' }
  end

  context 'when delivered' do
    before { subject.state = 'delivered' }
    its(:events)  { should include(:accept) }
    its(:events)  { should include(:reject) }
    its(:column)  { should == '#todo' }
  end

  context 'when rejected' do
    before { subject.state = 'rejected' }
    its(:events)  { should == [:restart] }
    its(:column)  { should == '#todo' }
  end

  context 'when accepted today' do
    before do
      subject.state = 'accepted'
      subject.accepted_at = Time.zone.now
    end
    its(:events)  { should == [] }
    its(:column)  { should == '#accepted' }
  end

  context 'when accepted last week' do
    before do
      subject.state = 'accepted'
      subject.accepted_at = 1.week.ago
    end
    its(:events)  { should == [] }
    its(:column)  { should == '#done' }
  end

  describe '#cache_user_names' do
    context 'when adding a requester and owner to a story' do
      let(:requester)  { create(:user) }
      let(:owner)      { create(:user) }
      let(:story) { create(:story, :with_project, owned_by: nil, requested_by: requester) }

      before do
        story.project.users << owner
        story.update(owned_by: owner)
      end

      specify { expect(story.requested_by_name).to eq(requester.name) }
      specify { expect(story.owned_by_name).to eq(owner.name) }
      specify { expect(story.owned_by_initials).to eq(owner.initials) }
    end

    context 'when removing a owner to a story' do
      let(:owner)     { create(:user) }
      let(:requester) { create(:user) }
      let(:project) { create(:project, users: [owner, requester]) }
      let(:story)   { create(:story, project: project, owned_by: owner, requested_by: requester) }

      before do
        story.update(owned_by: nil)
      end

      specify { expect(story.owned_by_name).to be_nil }
      specify { expect(story.owned_by_initials).to be_nil }
    end

    context 'when changing a requested and owner of a story' do
      let(:requester)     { create(:user) }
      let(:owner)         { create(:user) }
      let(:requester2)    { create(:user) }
      let(:owner2)        { create(:user) }
      let(:project)       { create(:project, users: [owner, owner2, requester, requester2]) }
      let(:story) { create(:story, project: project, owned_by: owner, requested_by: requester) }

      before do
        project.users + [owner, owner2, requester, requester2]
        story.update(owned_by: owner2, requested_by: requester2)
      end

      specify { expect(story.requested_by_name).to eq(requester2.name) }
      specify { expect(story.owned_by_name).to eq(owner2.name) }
      specify { expect(story.owned_by_initials).to eq(owner2.initials) }
    end
  end

  describe 'defaults' do
    subject { Story.new }

    its(:state)       { should == 'unscheduled' }
    its(:story_type)  { should == 'feature' }
  end

  describe 'scopes' do
    let!(:user) { create(:user) }

    let!(:project) do
      create(:project, users: [user])
    end

    let!(:story) { create(:story, :done, project: project, requested_by: user) }

    context '.accepted' do
      it 'include accepted story' do
        expect(Story.accepted).to include(story)
      end

      it 'not include non accepted story' do
        story.accepted_at = nil
        story.save!

        expect(Story.accepted).not_to include(story)
      end
    end

    context '.accepted_between()' do
      let(:start_date) { Time.current.days_ago(16) }
      let(:end_date) { Time.current.days_ago(14) }

      it 'include story accepted beetween start_date and end_date' do
        story.accepted_at = start_date + 2.days
        story.save!

        expect(Story.accepted_between(start_date, end_date)).to include(story)
      end

      it 'not include story accepted before start_date' do
        story.accepted_at = start_date - 1.day
        story.save!

        expect(Story.accepted_between(start_date, end_date)).not_to include(story)
      end

      it 'not include story accepted after end_date' do
        story.accepted_at = end_date + 1.day
        story.save!

        expect(Story.accepted_between(start_date, end_date)).not_to include(story)
      end
    end
  end

  describe '.can_be_estimated?' do
    STORY_TYPES = { feature: true, chore: false, bug: false, release: false }.freeze

    STORY_TYPES.each do |type, estimable|
      context "when check if a #{type} story is estimable" do
        it "returns #{estimable}" do
          expect(Story.can_be_estimated?(type)).to eq(estimable)
        end
      end
    end
  end
end
