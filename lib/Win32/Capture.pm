package Win32::Capture;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(CaptureScreen CaptureRect CaptureWindow CaptureWindowRect IsWindowVisible FindWindowLike SearchWindowText GetWindowText GetWindowRect GetClassName);

use Win32::API;
use Win32::GUI::DIBitmap;

$VERSION = '1.1';

BEGIN {
$GetDC                 = new Win32::API('user32','GetDC',['N'],'N');
$GetTopWindow          = new Win32::API('user32','GetTopWindow',['N'],'N');
$FindWindow            = new Win32::API('user32','FindWindow',['P','P'],'N');
$GetWindow             = new Win32::API('user32','GetWindow', ['N', 'N'], 'N');
$GetDesktopWindow      = new Win32::API('user32','GetDesktopWindow', [], 'N');
$GetClassName          = new Win32::API('user32','GetClassName', ['N', 'P', 'N'], 'N');
$GetWindowText         = new Win32::API('user32','GetWindowText', ['N', 'P', 'N'], 'N');
$GetWindowRect         = new Win32::API('user32','GetWindowRect', ['N', 'P'], 'N');
$SetForegroundWindow   = new Win32::API('user32','SetForegroundWindow', ['N'], 'N');
$IsWindowVisible       = new Win32::API('user32','IsWindowVisible', ['N'], 'N');
}

sub IsWindowVisible {
return $IsWindowVisible->Call($_[0]);
}

sub CaptureScreen() {
my $dc  = $GetDC->Call(0);
my $dib = newFromDC Win32::GUI::DIBitmap ($dc) or return undef;
return $dib;
}

sub CaptureRect($$$$) {
my $dc  = $GetDC->Call(0);
my $dib = newFromDC Win32::GUI::DIBitmap ($dc,$_[0],$_[1],$_[2],$_[3]) or return undef;
return $dib;
}

sub CaptureWindow($$$) {
my $win = $_[0];
$SetForegroundWindow->Call($win);
sleep $_[1];
my $dib = newFromWindow Win32::GUI::DIBitmap ($win,$_[2]) or return undef;
return $dib;
}

sub CaptureWindowRect($$$$$$) {
my $win = $_[0];
$SetForegroundWindow->Call($win);
sleep $_[1];
my $dc  = $GetDC->Call($win);
my $dib = newFromDC Win32::GUI::DIBitmap ($dc,$_[2],$_[3],$_[4],$_[5]) or return undef;
return $dib;
}


sub FindWindowLike {
my $pattern = shift;
my @array=();
my $parent = $GetDesktopWindow->Call();
my $hwnd = $GetWindow->Call($parent, 5);

while($hwnd) {
       my $windowname = SearchWindowText($hwnd,$pattern);
           if($windowname ne '') {
               push(@array,$hwnd);
           }
       $hwnd = $GetWindow->Call($hwnd, 2);
}

return @array;
}

sub SearchWindowText {
    my $hwnd = shift;
    my $pattern = shift;
    my $title = " " x 1024;
    my $titleLen = 1024;
    my $result = $GetWindowText->Call($hwnd, $title, $titleLen);
    $title=~s/\s+$//;
    if($title=~/\Q$pattern\E/i) {
        return $title;
    }else{
        return '';
    }
}

sub GetWindowText {
    my $hwnd = shift;
    my $title = " " x 1024;
    my $titlelen = 1024;
    my $result = $GetWindowText->Call($hwnd, $title, $titlelen);
    $title=~s/\s+$//;
    return $title;
}

sub GetWindowRect {
    my $hwnd = shift;
    my $RECT = pack("iiii", 0, 0);
    $GetWindowRect->Call($hwnd, $RECT);
    return wantarray ? unpack("iiii", $RECT) : $RECT;
}

sub GetClassName {
    my $hwnd = shift;
    my $name = " " x 1024;
    my $namelen = 1024;
    my $result = $GetClassName->Call($hwnd, $name, $namelen);
    $name=~s/\s+$//;
    return $name;
}

1;

__END__

=head1 NAME

Win32::Capture - Capature Win32 screen with lightweight Win32::GUI::DIBitmap.

=head1 SYNOPSIS

  use Win32::Capture;


  $image = CaptureScreen(); # Capture Whole screen.
  $image->SaveToFile('screenshot.png');

  #or

  $image = CaptureRect( $x, $y, $width, $height ); # Capture a part of window.
  $image->SaveToFile('screenshot.png');

  #or

  @WIN = FindWindowLike('CPAN'); # Find the HWND to be captured.

  if($#WIN<0) {
       print "Not found";
  }else{
        foreach(@WIN) {
            my $image = CaptureWindowRect($_,2,0,0,400,300);
            $image->SaveToFile("$_.jpg",JPEG_QUALITYSUPERB);
        }
  }

=head1 DESCRIPTION

The package is similar to L<Win32::Screenshot|Win32::Screenshot>, also using Win32 API function,
but with Image Process in L<Win32::GUI::DIBitmap|Win32::GUI::DIBitmap>
to let you capture the screen, a window or a part of it. The
C<Capture*(...)> functions returns a new L<Win32::GUI::DIBitmap|Win32::GUI::DIBitmap> object which
you can easily use to modify the screenshot or to store it in the
file.


=head2 Screen capture functions

All these functions return a new L<Win32::GUI::DIBitmap|Win32::GUI::DIBitmap> object
on success or undef on failure. These function are exported by default.

=over 8

=item CaptureRect( $x, $y, $width, $height )

Captures part of the screen. The [0, 0] coordinate is the upper-left
corner of the screen. The [$x, $y] defines the the upper-left corner
of the rectangle to be captured.

=item CaptureScreen( )

Captures whole screen including the taskbar.

=item CaptureWindow( $HWND , $sec , $flag )

Captures whole window including title and border or only for Client Window.
The second parameter is how many time wait for the Window be Changed to Top.

TIPS: You can using FindWindowLike to find the HWND.

  flag = 0 : All the window is capture (with border)
  flag = 1 : Only the Client window is capture

=item CaptureWindowRect( $HWND , $sec , $x, $y, $width, $height )

Captures a part of the window. Pass the window handle with the function
parameter. The second parameter is how many time wait for the Window be
Changed to Top.

TIPS: You can using FindWindowLike to find the HWND element(s).

=back

=head2 Capturing helper functions

Functions for find the Window HWND to capture.

=over 8

=item FindWindowLike( $pattern )

  @WIN = FindWindowLike('CPAN');

  if($#WIN<0) {
       print "Not found";
  }else{
        foreach(@WIN) {
            my $image = CaptureWindowRect($_,2,0,0,400,300);
            $image->SaveToFile("$_.jpg",JPEG_QUALITYSUPERB);
        }
  }

The parameter is a part of window title, and FindWindowLike will Return
an Array including HWND.

=back

=head1 SEE ALSO

=over 8

=item Win32::Screenshot

Some documentation refer from here.

=item Win32::GUI::DIBitmap

The raw data from the screen are loaded into Win32::GUI::DIBitmap object.
You have a lot of possibilities what to do with the captured image.

=item MSDN

http://msdn.microsoft.com/library

=back

=head1 INSTALL With ActiveState PPM

   ppm install http://kenwu.idv.tw/Win32-Capture.ppd

=head1 AUTHOR

Lilo Huang

kenwu@cpan.org

http://blog.yam.com/kenwu/


=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Lilo Huang All Rights Reserved.

You can use this module under the same terms as Perl itself.

=cut