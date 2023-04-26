module StoryOperations
  class DestroyAll
    include Dry::Monads[:result, :do]

    def call(stories:, current_user:)
      deleted_stories = yield destroy_stories(
        stories: stories
      )

      yield create_activity(deleted_stories, current_user: current_user)

      Success(deleted_stories)
    rescue
      Failure(false)
    end

    private

    def destroy_stories(stories:)
      deleted_stories = stories.destroy_all
      Success(deleted_stories)
    end

    def create_activity(stories, current_user:)
      Success ::Base::ActivityRecording.create_activity(
        stories,
        current_user: current_user,
        action: 'destroy'
      )
    end
  end

  class ReadAll
    include Dry::Monads[:result, :do]

    delegate :past_iterations, :current_iteration_start, to: :iterations

    def call(project:)
      @project = project

      yield active_stories
      yield project_iterations

      Success(
        active_stories: @active_stories,
        past_iterations: past_iterations
      )
    end

    private

    attr_reader :project

    def iterations
      @project_iterations ||= Iterations::ProjectIterations.new(project: project)
    end

    def project_iterations
      @project_iterations ||= iterations
      Success(@project_iterations)
    end

    def active_stories
      @active_stories ||= begin
        project
          .stories
          .with_dependencies
          .where("state != 'accepted' OR accepted_at >= ?", current_iteration_start)
          .order('updated_at DESC')
      end

      Success(@active_stories)
    end
  end
end
