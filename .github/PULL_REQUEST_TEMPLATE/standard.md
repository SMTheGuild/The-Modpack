---
name: Standard pull request
about: Create a request to merge changes previously discussed in an issue.
title: ''
labels: ''
assignees: ''
---

<!-- These comments explain each section's purpose and level of detail. They can be omitted in the final pull request.
Don't forget to base/target your PR on the dev branch! -->

## Resolves #<!-- Insert the referenced issue's number here -->

## Description
<!-- Describe what your pr changes. Does it fix a bug? add a feature? something else?
Does your PR have urgence? (priority/severity: [1.Low | 2.Medium | 3.High | 4. Critical])
Optional: a reason to merge this pull request
Optional: a reason for chosen development changes -->


## Testing
<!-- What behaviour was tested to guarantee this PR's changes to work
Mark a list entry as resolved using an "x" in the brackets: "[x]" -->
- [ ] Mod was tested to load successfully in a new world
- [ ] The changes(new feature/enhancement/bugfix) was tested in a new world
- [ ] The changes are tested for impact on other parts/features
- [ ] These changes don't break existing functionality
- [ ] Mod was tested in a world that tests all mod functionality
- [ ] Changes were reviewed to not have any left over testing changes (debug `print`s, commented out code, mesh data)

#### Additional testing <!-- This section is optional and can be removed if unnecessary -->
<!-- Describe additional tests you have done
eg. I did X to test if Y didn't break affected functionality X -->

## Pull request process
<!-- Mark a list entry as resolved using an "x" in the brackets: "[x]" -->
- [ ] I have reviewed every section of this template and filled them out carefully and with enough detail for others to check my changes easily
- [ ] I have set an appropriate title for this pull request
- [ ] I attempted to add appropriate reviewers/assignees/labels/linked issues to this pull request
