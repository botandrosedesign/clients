Feature: Stories can be deleted
  Background:
    Given the following users exist:
      | email                | name         | initials | teams | projects        |
      | micah@botandrose.com | Micah Geisel | MG       | BARD  | Example Project |

    And the "Example Project" project has the following stories:
      | type    | title | state       |
      | feature | WOW   | unscheduled |

  Scenario: User deletes a story
    Given I am logged in as "micah@botandrose.com"
    When I follow "Select project" within the "Example Project" project
    Then I should see the following project board:
      | Done | Current | Icebox      |
      |      |         | F WOW start |

    When I open the "WOW" story
    And I press "Delete"
    Then I should see the following project board:
      | Done | Current | Icebox |
