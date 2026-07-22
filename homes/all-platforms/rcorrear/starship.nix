# This is the upstream "Jetpack" preset, translated from TOML to Nix:
# https://starship.rs/presets/jetpack
#
# `programs.starship.enable` itself is set in ./default.nix; this module
# only carries the preset's settings.
#
# Disabling stylix's own `targets.starship` (so it relies on the
# terminal's palette for the named colors below, e.g. "purple",
# "bright-yellow") is handled once, for every `homeManager`-class target
# (both the embedded nix-darwin/NixOS home-manager instances and the
# standalone `homeConfigurations."rcorrear@<host>"` entities), directly in
# `den.aspects.stylix.homeManager` (modules/aspects/stylix.nix) — no
# override is needed here.
{ pkgs, ... }:
{
  home.packages = [
    # Backs the [custom.jj] module below.
    pkgs.starship-jj
  ];

  programs.starship.settings = {
    "$schema" = "https://starship.rs/config-schema.json";

    add_newline = true;
    continuation_prompt = "[▸▹ ](dimmed white)";

    format = "($nix_shell$container$fill$git_metrics\n)$cmd_duration$hostname$localip$shlvl$shell$env_var$jobs$sudo$username$character";

    right_format = "$singularity$kubernetes$directory$vcsh$fossil_branch$git_branch$git_commit$git_state$git_status$hg_branch$pijul_channel$docker_context$package$c$cpp$cmake$cobol$daml$dart$deno$dotnet$elixir$elm$erlang$fennel$fortran$golang$guix_shell$haskell$haxe$helm$java$julia$kotlin$gradle$lua$maven$nim$nodejs$bun$ocaml$opa$perl$php$pulumi$purescript$python$raku$rlang$red$ruby$rust$scala$solidity$swift$terraform$vlang$vagrant$xmake$zig$buf$conda$pixi$meson$spack$memory_usage$aws$gcloud$openstack$azure$crystal$custom$status$os$battery$time";

    fill.symbol = " ";

    character = {
      format = "$symbol ";
      success_symbol = "[◎](bold italic bright-yellow)";
      error_symbol = "[○](italic purple)";
      vimcmd_symbol = "[■](italic dimmed green)";
      # not supported in zsh
      vimcmd_replace_one_symbol = "◌";
      vimcmd_replace_symbol = "□";
      vimcmd_visual_symbol = "▼";
    };

    env_var.VIMSHELL = {
      format = "[$env_value]($style)";
      style = "green italic";
    };

    sudo = {
      format = "[$symbol]($style)";
      style = "bold italic bright-purple";
      symbol = "⋈┈";
      disabled = false;
    };

    username = {
      style_user = "bright-yellow bold italic";
      style_root = "purple bold italic";
      format = "[⭘ $user]($style) ";
      disabled = false;
      show_always = false;
    };

    directory = {
      home_symbol = "⌂";
      truncation_length = 2;
      truncation_symbol = "□ ";
      read_only = " ◈";
      use_os_path_sep = true;
      style = "italic blue";
      format = "[$path]($style)[$read_only]($read_only_style)";
      repo_root_style = "bold blue";
      repo_root_format = "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) [△](bold bright-blue)";
    };

    cmd_duration.format = "[◄ $duration ](italic white)";

    jobs = {
      format = "[$symbol$number]($style) ";
      style = "white";
      symbol = "[▶](blue italic)";
    };

    localip = {
      ssh_only = true;
      format = " ◯[$localipv4](bold magenta)";
      disabled = false;
    };

    time = {
      disabled = false;
      format = "[ $time]($style)";
      time_format = "%R";
      utc_time_offset = "local";
      style = "italic dimmed white";
    };

    battery = {
      format = "[ $percentage $symbol]($style)";
      full_symbol = "█";
      charging_symbol = "[↑](italic bold green)";
      discharging_symbol = "↓";
      unknown_symbol = "░";
      empty_symbol = "▃";
      display = [
        {
          threshold = 20;
          style = "italic bold red";
        }
        {
          threshold = 60;
          style = "italic dimmed bright-purple";
        }
        {
          threshold = 70;
          style = "italic dimmed yellow";
        }
      ];
    };

    git_branch = {
      disabled = true;
      format = " [$branch(:$remote_branch)]($style)";
      symbol = "[△](bold italic bright-blue)";
      style = "italic bright-blue";
      truncation_symbol = "⋯";
      truncation_length = 11;
      ignore_branches = [
        "main"
        "master"
      ];
      only_attached = true;
    };

    git_metrics = {
      format = "([▴$added]($added_style))([▿$deleted]($deleted_style))";
      added_style = "italic dimmed green";
      deleted_style = "italic dimmed red";
      ignore_submodules = true;
      disabled = false;
    };

    git_status = {
      disabled = true;
      style = "bold italic bright-blue";
      format = "([⎪$ahead_behind$staged$modified$untracked$renamed$deleted$conflicted$stashed⎥]($style))";
      conflicted = "[◪◦](italic bright-magenta)";
      ahead = "[▴│[\${count}](bold white)│](italic green)";
      behind = "[▿│[\${count}](bold white)│](italic red)";
      diverged = "[◇ ▴┤[\${ahead_count}](regular white)│▿┤[\${behind_count}](regular white)│](italic bright-magenta)";
      untracked = "[◌◦](italic bright-yellow)";
      stashed = "[◃◈](italic white)";
      modified = "[●◦](italic yellow)";
      staged = "[▪┤[$count](bold white)│](italic bright-cyan)";
      renamed = "[◎◦](italic bright-blue)";
      deleted = "[✕](italic red)";
    };

    # jj-vcs support: `git_branch`/`git_status` above are disabled since
    # they only understand git, and a colocated `.jj`+`.git` repo would
    # otherwise show git's (empty/stale) status instead of jj's. This
    # custom module runs `starship-jj` (added to home.packages above)
    # whenever a `.jj` directory is found, showing jj's own status line.
    custom.jj = {
      command = "prompt";
      format = "$output";
      ignore_timeout = true;
      shell = [
        "starship-jj"
        "--ignore-working-copy"
        "starship"
      ];
      use_stdin = false;
      when = true;
    };

    # Fallback for plain (non-jj-colocated) git repos, since `git_status`
    # is disabled above.
    custom.git_fallback = {
      command = ''
        branch=$(git branch --show-current 2>/dev/null)
        if [ -n "$branch" ]; then
            echo "$branch"
        fi
      '';
      # Only git, never jj (including jj-colocated) repos.
      when = "test -d .git && ! test -d .jj";
      style = "bold green";
      format = "on [git:($output)]($style) ";
    };

    deno = {
      format = " [deno](italic) [∫ $version](green bold)";
      version_format = "\${raw}";
    };

    lua = {
      format = " [lua](italic) [\${symbol}\${version}]($style)";
      version_format = "\${raw}";
      symbol = "⨀ ";
      style = "bold bright-yellow";
    };

    nodejs = {
      format = " [node](italic) [◫ ($version)](bold bright-green)";
      version_format = "\${raw}";
      detect_files = [
        "package-lock.json"
        "yarn.lock"
      ];
      detect_folders = [ "node_modules" ];
      detect_extensions = [ ];
    };

    bun = {
      format = " [bun](italic) [◫ ($version)](bold bright-green)";
      version_format = "\${raw}";
    };

    python = {
      format = " [py](italic) [\${symbol}\${version}]($style)";
      symbol = "[⌉](bold bright-blue)⌊ ";
      version_format = "\${raw}";
      style = "bold bright-yellow";
    };

    ruby = {
      format = " [rb](italic) [\${symbol}\${version}]($style)";
      symbol = "◆ ";
      version_format = "\${raw}";
      style = "bold red";
    };

    rust = {
      format = " [rs](italic) [$symbol$version]($style)";
      symbol = "⊃ ";
      version_format = "\${raw}";
      style = "bold red";
    };

    package = {
      format = " [pkg](italic dimmed) [$symbol$version]($style)";
      version_format = "\${raw}";
      symbol = "◨ ";
      style = "dimmed yellow italic bold";
    };

    swift = {
      format = " [sw](italic) [\${symbol}\${version}]($style)";
      symbol = "◁ ";
      style = "bold bright-red";
      version_format = "\${raw}";
    };

    aws = {
      disabled = true;
      format = " [aws](italic) [$symbol $profile $region]($style)";
      style = "bold blue";
      symbol = "▲ ";
    };

    buf = {
      symbol = "■ ";
      format = " [buf](italic) [$symbol $version $buf_version]($style)";
    };

    c = {
      symbol = "ℂ ";
      format = " [$symbol($version(-$name))]($style)";
    };

    cpp = {
      symbol = "ℂ ";
      format = " [$symbol($version(-$name))]($style)";
    };

    conda = {
      symbol = "◯ ";
      format = " conda [$symbol$environment]($style)";
    };

    pixi = {
      symbol = "■ ";
      format = " pixi [$symbol$version ($environment )]($style)";
    };

    dart = {
      symbol = "◁◅ ";
      format = " dart [$symbol($version )]($style)";
    };

    docker_context = {
      symbol = "◧ ";
      format = " docker [$symbol$context]($style)";
    };

    elixir = {
      symbol = "△ ";
      format = " exs [$symbol $version OTP $otp_version ]($style)";
    };

    elm = {
      symbol = "◩ ";
      format = " elm [$symbol($version )]($style)";
    };

    golang = {
      symbol = "∩ ";
      format = " go [$symbol($version )]($style)";
    };

    haskell = {
      symbol = "❯λ ";
      format = " hs [$symbol($version )]($style)";
    };

    java = {
      symbol = "∪ ";
      format = " java [\${symbol}(\${version} )]($style)";
    };

    julia = {
      symbol = "◎ ";
      format = " jl [$symbol($version )]($style)";
    };

    memory_usage = {
      symbol = "▪▫▪ ";
      format = " mem [\${ram}( \${swap})]($style)";
    };

    nim = {
      symbol = "▴▲▴ ";
      format = " nim [$symbol($version )]($style)";
    };

    nix_shell = {
      style = "bold italic dimmed blue";
      symbol = "✶";
      format = "[$symbol nix⎪$state⎪]($style) [$name](italic dimmed white)";
      impure_msg = "[⌽](bold dimmed red)";
      pure_msg = "[⌾](bold dimmed green)";
      unknown_msg = "[◌](bold dimmed yellow)";
    };

    spack = {
      symbol = "◇ ";
      format = " spack [$symbol$environment]($style)";
    };
  };
}
