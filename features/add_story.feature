Feature: Stories can be added
  Background:
    Given the following users exist:
      | email                | name         | initials |
      | micah@botandrose.com | Micah Geisel | MG       |

    Given the following projects exist:
      | name            | users                |
      | Example Project | micah@botandrose.com |

    Given the following teams exist:
      | name | projects        | users                |
      | BARD | Example Project | micah@botandrose.com |

    And the "Example Project" project has the following stories:
      | type    | title | state       |
      | feature | WOW   | unscheduled |

  Scenario: Create a new story
    Given I am logged in as "micah@botandrose.com"
    And I am on the "Example Project" project page
    Then I should see the following project board:
      | Done | Current | Icebox      |
      |      |         | F WOW start |

    When I follow "Add story"
    Then I should see the following new story form:
      | Title        |             |
      | Story type   | feature     |
      | State        | unscheduled |
      | Requested by |             |
      | Owned by     |             |
      | Labels       |             |
      | Description  |             |

    When I fill in the following form:
      | Title        | WOW!         |
      | Story type   | bug          |
      | State        | started      |
      | Requested by | Micah Geisel |
      | Owned by     | Micah Geisel |
      | Labels       | test         |
      | Description  | description  |
    And I press "Save"
    Then I should see the following project board:
      | Done | Current          | Icebox      |
      |      | B WOW! MG finish | F WOW start |

