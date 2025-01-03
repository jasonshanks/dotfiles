# dotfiles...a neverending story by Jason Shanks

dotfiles. What self-respecting nerd wouldn't maintaining their own dotfiles repo, am I right?

There's 4 main reasons why dotfiles are important:

1. **Backup & Restore**: If you need to restore your computer for any reason, your physical backup may not be available or in a complete state. Suffice it say, they more you invest in customising your system, the more painful it would be to recreate.
2. **Portability**: You need portability to spin up your working environment on another machine.
3. **Reference**: A historical reference log of how your systems, tools and practices have evolved over time.
4. **Inspiration**: To share inspiration with the greater community. I have and continue to learn a tremendous amount from how others maximise and personalise their favourite tools.

These are mine in an ever evolving state. Pick from it what you will, or [Fork it](https://github.com/jasonshanks/dotfiles/fork), remove what you don't use, and build on what you do!

## Organisation

For now, it is largely a clone of the select pieces of my .config directory that are not transitional. There are a sprinkling of other non-dotfile related settings outside of that. I may further organise these into thematical folders at some point if necessary.

## DEV

These files are not currently in use and mostly borrowed from other dotfile systems waiting to be incorporated, discarded or awaiting decision on my overall bootstrapping approach.

## 🙏Thanks and 📣shoutouts

Thanks to the entire Open Source community and by extension Github. To all those who graciously share their dotfiles, tips, code contributions, not to mention literally every application I so preciously preserve my settings for here!! I ♥️ Open Source! My computing life would be all the less richer without it.

📣shoutouts to:

- [Zach Holman](https://zachholman.com/2010/08/dotfiles-are-meant-to-be-forked/) and [Andrew Burgess](https://shaky.sh/simple-dotfiles/) - for the inspiration to organise by thematical folders and to include a bootstrap script to auto copy and symlink everything needed to configure a new system.
- [Brian Mayo](https://medium.com/@protiumx/bash-gnu-stow-take-a-walk-while-your-new-macbook-is-being-set-up-351a6f2f9225) - for the 'reach for the sky' idea that you could wrap all your Mac apps, preferences and defaults up with this too!

## TODO

- [ ] Migrate the remainder of legacy configs not yet symlinked.
- [ ] Decide on symlink approach (custom variation on inspo above, Stow, or maybe [Chezmoi](https://www.chezmoi.io) or [YADM](https://yadm.io/#))
- [ ] Finalise boostrap and restore method.
- [ ] Adapt scripts to 🐟fish shell.
- [ ] Incorporate `mas` for Mac App Store restoration
- [ ] Incorporate Brew packages/taps/brews reinstall scripts
- [ ] Incorporate main Mac Preferences backup
- [ ] Collect all my Mac defaults and store for restoration

UPDATED: 2025-01-04
