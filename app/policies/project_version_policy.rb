class ProjectVersionPolicy < ApplicationPolicy
  def show?
    # Admins can always see project versions.
    return true if user&.admin?

    # If no record, can't show it.
    # Note: record is a ProjectVersion.
    return false unless record

    # Users can see project versions attached to a course they are enrolled in.
    record.courses.each do |course|
      course.sections.each do |section|
        RoleConstants::SECTION_ROLES.each do |role|
          return true if user.has_role? role, section
        end
      end
    end

    false
  end
end
