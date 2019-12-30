#!/usr/bin/env bash

set -e

repo=${repo:-t184256/nix-on-droid-bootstrap}  # set this to your fork!
branch=${branch:-$(git rev-parse --abbrev-ref HEAD)}

arches='aarch64 i686'
nixOnDroidChannelURL=https://github.com/$repo/archive/$branch.tar.gz

mkdir -p out
rm -f out/*
for arch in $arches; do
	echo $arch: building talloc...
	nix build --show-trace -f pkgs --argstr arch $arch tallocStatic -o out/talloc-$arch
	talloc=$(realpath out/talloc-$arch)

	echo $arch: building proot...
	nix build --show-trace -f pkgs --argstr arch $arch prootTermux -o out/proot-$arch
	proot=$(realpath out/proot-$arch)

	echo $arch: patching proot path in modules/environment/login/default.nix...
	grep "$arch = \"/nix/store/" modules/environment/login/default.nix
	sed -i "s|$arch = \"/nix/store/.*\";|$arch = \"$proot\";|" modules/environment/login/default.nix
	grep "$arch = \"/nix/store/" modules/environment/login/default.nix

	echo $arch: building nix-on-droid...
	nix build --show-trace -f pkgs --argstr arch $arch --argstr nixOnDroidChannelURL $nixOnDroidChannelURL bootstrapZip -o out/nix-on-droid-$arch

	echo $arch: injecting talloc/proot for initial bootstrap...

	cat out/nix-on-droid-$arch/bootstrap-$arch.zip > out/bootstrap-$arch.zip
	nix-store --export --readonly-mode $talloc > out/talloc-$arch.closure
	nix-store --export --readonly-mode $proot > out/proot-$arch.closure

	mkdir out/repack-$arch
	pushd out/repack-$arch >/dev/null
	unzip -q ../bootstrap-$arch.zip
	rm ../bootstrap-$arch.zip
	cp ../talloc-$arch.closure ./talloc.closure
	cp ../proot-$arch.closure ./proot.closure
	zip --quiet -r ../bootstrap-$arch.zip .
	popd >/dev/null
	chmod -R +w out/repack-$arch
	rm -rf out/repack-$arch
	echo $arch: done
done


if [ -z "$rsync_to" ]; then
	echo 'Done. Now put out/bootstrap-*.zip on some HTTP server and point the app to it. Good luck!'
else
	if [ $branch == master ]; then
		rsync -vP out/bootstrap-*.zip "$rsync_to/bootstrap/"
	else
		rsync -vP out/bootstrap-*.zip "$rsync_to/bootstrap-$branch/"
	fi
fi
