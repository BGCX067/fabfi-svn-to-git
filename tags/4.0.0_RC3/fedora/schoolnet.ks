# Desktop with customizationst to fit in a CD sized image (package removals, etc.)
# Maintained by the Fedora Desktop SIG:
# http://fedoraproject.org/wiki/SIGs/Desktop
# mailto:desktop@lists.fedoraproject.org

%include /usr/share/spin-kickstarts/fedora-live-desktop.ks
%include /usr/share/spin-kickstarts/fedora-live-minimization.ks

%include include/minimal.ks
%include include/wordpress.ks
%include include/canvas-lsm.ks
%include include/reddit.ks

%packages
# strip these
-gvnc
-vnc

%end

%post
touch /schoolnetwuzhere
%end
