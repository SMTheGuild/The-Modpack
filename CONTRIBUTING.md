# Contribute to The Modpack

[**How do I contribute?**](#how-do-i-contribute)
- [Create issues](#create-issues)
- [Contribute code](#contribute-code)  

[**Guidelines**](#guidelines)
- [Naming conventions](#naming-conventions)
- [Folder structure](#folder-structure)
- [Source control](#source-control)
- [Pull request == feature](#pull-request--feature)

## How do I contribute?

### Create issues

You can create issues [here](https://github.com/SMTheGuild/The-Modpack/issues).  
*What can you do there?*
- Report bugs.
- Request fixes.
- Request features.
- Ask questions.

Before you create a new issue, please do a search in open issues to see if the issue or feature request has already been filed.  
If you find your issue already exists, make relevant comments and add your reaction.  
Use a reaction in place of a "+1" comment:  
👍 - upvote  
👎 - downvote  
If you cannot find an existing issue that describes your bug or feature, create a new issue.   

### Contribute code

If you want to add features, fix bugs, or do any other changes. you can do so!  
Even contributing to this *contributing guidelines* file is possible!

<details>
  <summary>Click to show a <b>Contribution tutorial</b></summary>
    <ol>
      <li>Sign up or login to <a href="https://github.com/login">Github</a>.</li>
      <li>Download <a href="https://desktop.github.com/">Github Desktop</a>.</li>
      <li>
        Fork the <a href="https://github.com/SMTheGuild/The-Modpack">'The Modpack'</a> repository.
        <br>
        <img src="https://raw.githubusercontent.com/SMTheGuild/The-Modpack/dev/.github/img/fork.png" alt="fork.png">
      </li>
      <li>
        Clone your forked repository.
        <br>
        A. Click the 'Code' button and 'Open with github desktop' button.
        <br>
        <img src="https://raw.githubusercontent.com/SMTheGuild/The-Modpack/dev/.github/img/clone.png" alt="clone.png">
        <br>
        B. Click 'Open GitHubDesktop.exe'
        <br>
        <img src="https://raw.githubusercontent.com/SMTheGuild/The-Modpack/dev/.github/img/opengithubdesktop.png" alt="opengithubdesktop.png">
        <br>
        C. Choose your mods folder and click 'clone'.
        <br>
        <img src="https://raw.githubusercontent.com/SMTheGuild/The-Modpack/dev/.github/img/localclone.png" alt="localclone.png">
      </li>
      <li>
        In Github Desktop, Select the 'dev' branch.
        <br>
        <img src="https://raw.githubusercontent.com/SMTheGuild/The-Modpack/dev/.github/img/choosedevbranch.png" alt="choosedevbranch.png">
      </li>
      <li>
        Create your local changes.
        <br>
        ⚠️ To test out your changes, copy the <code>.../Mods/The-Modpack/dist/description.json</code> and <code>.../Mods/The-Modpack/dist/preview.jpg</code> files to your <code>.../Mods/The-Modpack/</code> folder.
      </li>
      <li>
        Commit your changes in github desktop by providing a useful commit message, clicking 'Commit to dev' and then 'Fetch origin'/'Push origin' at the top.
        <br>
        <img src="https://raw.githubusercontent.com/SMTheGuild/The-Modpack/dev/.github/img/commit.png" alt="commit.png">
      </li>
      <li>
        If you are happy with your changes you can open a pull request.<br>
        A. Go to your forked repository page (example: https://github.com/brentbatch/The-Modpack/)
        <br>
        B. Open the tab 'Pull Requests'
        <br>
        C. Click 'new pull request'
        <br>
        D. Select the 'dev' branch for both repositories as shown below
        <br>
        E. Click 'Create pull request'
        <br>
        F. We'll take it from here! :)
        <img src="https://raw.githubusercontent.com/SMTheGuild/The-Modpack/dev/.github/img/pullrequest.png" alt="pullrequest.png">
      </li>
    </ol>
</details>
<br>

## Guidelines

### Naming conventions

A Lua file should only define a **maximum** of **one class**. Classes should be named in PascalCase.  
If a Lua file defines a class, it should be named ``<ClassName>.lua``.

### Folder structure

**Folder names** inside ``Scripts/`` should be in lowercase.  
**Interactable class** files should be located in ``Scripts/interactable/``.  
**Tool class** files should be located in ``Scripts/tool/``.  
**Libraries and utility scripts** should be located in ``Scripts/libs/``.  
**Json data files** should be located in ``Scripts/data/`` and be named in underscore_case (e.g. shape_database.json).

### Source control

Before you start working on your own changes make sure to pull the latest **upstream** changes. (Changes on the SMTheGuild 'The Modpack' repository)  
You can do this by going to your forked repository in browser and clicking the 'Fetch upstream' button.
⚠️ Only applies to you if your forked repository (dev!) is <strong><em>behind</em></strong> of <code>SMTheGuild:dev</code>!

<details>
  <summary>GitHub screenshot</summary>
  <img src="https://raw.githubusercontent.com/SMTheGuild/The-Modpack/dev/.github/img/fetchupstream.png" alt="fetchupstream.png">
</details>
<br>

### Pull Request == feature

Every pull request you do should only be about few changes. This could be a pull request adding a new feature to a certain part, or editing a language file, or some other change. But not 'some minor changes' here and there without a descriptive theme generalizing all those changes.

#### Good examples:
- "**Fixing typo's**": a pull request where **only** part description typo's are fixed.
- "**Rgb block lua performance fix**": a pull request with changes to fix rgb block performance issues.
- "**Add portal gun**": a pull request that adds the 'portal gun' part (includes *all* required changes; part.json, lua code, language descriptions, ...)

#### BAD examples:
- "**Minor fixes**": a pull request with random whitespace changes, adding comments, changing variable names, delete unused file, ...
- "**Mathblock vector support**": a pull request that adds some feature in the **orienter**

#### Exceptions:
- "**Mod X compatibility support**": a pull request with changes required to have compatibility with mod X without breaking existing functionality.
