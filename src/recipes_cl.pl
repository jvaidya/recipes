#!/usr/bin/perl

use lib 'c:/softmeld/dev/sbas/lib';
use lib '/home/softmeld/www/cgi-bin/service/lib';
use lib '/home/softmeld/www/cgi-bin/service/perl';
use CGI ':standard';
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use utils;
use SBAS::XMLFile;

if ($^O =~ /win32/i) {
    $DATAFILE = 'c:/temp/Recipes.xml';
} else {
    $DATAFILE = '/Users/jiten/private/softmeld/public_html/cgi-bin/private/Recipes.xml';
}

########################################################################

my $DEBUG = 1; 

########################################################################

$title = "Jiten and Alicia's Recipes";

########################################################################
$query = new CGI;

show_frontpage();
write_recipes();


sub old_main
{
$query = new CGI;
print_head($query,$title);
$Action = $query->param('Action');
$Action = $query->url_param('Action') if $Action eq "";
$Admin = 1 if $query->url_param('Admin') =~ /Jiten|Alicia/;
if ($Action eq "Edit") {
    print_prompt($query);
} elsif ($Action eq "New") {
  print_prompt($query);
} elsif ($Action eq "Publish") {
  do_work_save($query);
  $Admin = 1;
  show_frontpage($query);
} elsif ($Action eq "Show") {
    show_recipe($query);
} elsif ($Action eq "Delete") {
    delete_recipe($query);
    $Admin = 1;
    show_frontpage($query);
} else {
  show_frontpage($query);
}
print_tail($query);
}

########################################################################
 
sub show_frontpage
{
    my $recipes = readDataWithLock();
    open OUTFILE, ">recipes.html" or die $!;
    $ORIG_STDOUT = *STDOUT;
    *STDOUT = *OUTFILE;
    print_head($query,$title,"NOHEAD");
    ## Non-admin front page ######################################

    if (! $Admin) {
	print "<table BORDER=1>";
	foreach my $r (@{$recipes->{'records'}}) {
	    my $t_url = $r->{'title'};
	    my $view = "<A HREF=\"recipe_files/recipe_$r->{'count'}.html\">$r->{'title'}</A><BR>";
	    print_row($view);
	}
	print "</table>\n";
	return;
    }
    ## Admin front page ###########################################

    my $newt = "<A HREF=\"$myurl\?Action=New\">Create new recipe</A><BR>";
    print $newt; print "<P>\n";
    print "<table BORDER=1>";
    foreach my $r (@{$recipes->{'records'}}) {
	my $t_url = $r->{'title'};
	my $view = "<A HREF=\"$myurl\?Action=Show\&Count=$r->{'count'}\">View</A><BR>";
	my $edit = "<A HREF=\"$myurl\?Action=Edit\&Count=$r->{'count'}\">Edit</A><BR>";
	my $newt = "<A HREF=\"$myurl\?Action=New\&Count=$r->{'count'}\">Create new using this as template</A><BR>";
	my $delete = "<A HREF=\"$myurl\?Action=Delete\&Count=$r->{'count'}\">Delete</A><BR>";
	print_row($r->{'title'},$view,$edit,$delete,$newt);
    }
    print "</table>\n";
    print_tail($query);
    *STDOUT = $ORIG_STDOUT;
}

sub write_recipes
{
    my $recipes = readDataWithLock();

    foreach my $r (@{$recipes->{'records'}}) {

	show_recipe($r->{'count'});
    }
}

sub show_recipe
{
    #my $query = shift;
    my $count = shift;
    my $recipe = read_record($count);
    open OUTFILE, ">recipe_files/recipe_$count.html" or die $!;
    $ORIG_STDOUT = *STDOUT;
    *STDOUT = *OUTFILE;
    print_head($query,$title,"NOHEAD");
    print "<H2>$recipe->{'title'}</H2><HR>\n";    

    print "<table BORDER=2 CELLSPACING=5>";
    print "<tr>";
    print "<td VALIGN=top>";

    print "<B>Ingredients:</B><BR>\n";
    my $cnt = 0;
    print "<table CELLSPACING=10>";
    foreach my $i (@{$recipe->{'ingredients'}}) {
	$cnt++;
	if ($i->{'measure'} eq "SectionHeading") {
	    print "</table><BR>\n";
	    print "<B><I>$i->{'comment'}</B></I><BR>\n";
	    print "<table CELLSPACING=10><BR>\n";
	    $cnt = 0;
	    next;
	}
	foreach my $k (keys %$i) {
	    $i->{$k} = "" if $i->{$k} =~ /HASH/;
	}
	my $ic = $i->{'ingredient'};
	$ic .= ", $i->{'comment'}" if ($i->{'comment'} ne "");
	print_row($i->{'amount'},$i->{'measure'},$ic);
    }

    print "</table><BR>\n";

    print "</td>";
    print "<td VALIGN=top>";

    print "<B>Directions:</B><BR><BR>\n";
    $cnt = 0;
    print "<table CELLSPACING=10>";
    foreach my $i (@{$recipe->{'directions'}}) {
	$cnt++;
	my $txt = $i;
	$txt = $i->{'text'} if ref($i);
	print_row("$cnt.",$txt);
    }
    print "</table>";

    print "</td>";
    print "</tr>";
    print "</table>";
    print_tail($query);
    *STDOUT = $ORIG_STDOUT;
}

sub print_prompt {
   my($query) = @_;
   my $rec = read_record($query->param('Count'));
   my @measures = sort("Ounce","Pound","Gram","Inch","Square Inch","Pieces","Count","SectionHeading","Gallon","Pint","Pinch");
   unshift(@measures,("t.","T.","Cup"));
   my $title = $rec->{'title'};
   $title .= "CHANGE THIS " if $Action eq "New" and $title ne "";
   print $query->start_form;
   print $query->hidden('New','1') if $Action eq "New";
   print "<table BORDER=1>";
   print_row("<B>Title</B>",$query->textfield('recipe_title',$title,80));
   my $row_count = $rec->{'row_count'};
   $row_count = 15 if $row_count eq "";

   print "</table>\n";
   print "<BR>";
   print "<table BORDER=1>";
   print_row("<B>Ingredients:</B>","<B>Directions:</B>");
   print "<tr>\n";
   print "<td>\n";
   print "<table BORDER=1>";

   print_row("<B>Num</B>","<B>Amount</B>","<B>Measure</B>","<B>Ingredient</B>",
	     "<B>Comment</B>");

   for ($i = 1; $i < $row_count + 1; $i++) {
       my $ind = $i - 1;
       my $ing = ${$rec->{'ingredients'}}[$ind];
       foreach my $k (keys %$ing) {
	    $ing->{$k} = "" if $ing->{$k} =~ /HASH/;
       }
       print_row($query->textfield("number_${i}",$i,3),
                 $query->textfield("amount_${i}",$ing->{'amount'},5),
		 $query->popup_menu("measure_${i}",\@measures,$ing->{'measure'}),
		 $query->textfield("ingredient_${i}",$ing->{'ingredient'},10),
		 $query->textfield("comment_${i}",$ing->{'comment'},15),
		 );
   }
   print_row("<B>Row Count</B>",$query->textfield('row_count',$row_count,3));
   print "</table>\n";
   print "</td>\n";
   print "<td>\n";
   print "<table BORDER=1>";
   print_row("<B>Step</B>","<B>Text</B>");
   for ($i = 1; $i < $row_count + 1; $i++) {
       my $dt = ${$rec->{'directions'}}[$i-1];
       $dt = $dt->{'text'} if ref($dt);
       print_row($query->textfield("step_${i}",$i,3),
		 $query->textfield("text_${i}",$dt,60),
		 );
   }
#   print_row($query->textarea(-name=>'content',
#			  -default => $script_val,
#                          -rows=>20,
#                          -columns=>60));
   print "</table>\n";
   print "</td>\n";
   print "</tr>\n";
   print "</table>\n";

   print $query->hr;

   print $query->submit('Action','Publish');
   print $query->endform;
}

sub do_work_save
{
    my $query = shift;
    save_record($query);
    print "Record Saved<BR><HR>";
}

sub delete_recipe
{
    my $query = shift;
    delete_record($query->url_param('Count'));
    print "Record Deleted<BR><HR>";
}

sub delete_record
{
    my $count = shift;
    my $lockf = $DATAFILE.".lck";
    my $lock = lock($lockf);
    my $recipes = readData();
    my $newrecords;
    foreach my $r (@{$recipes->{'records'}}) {
	push(@{$newrecords},$r) unless $r->{'count'} == $count;
    }
    $recipes->{'records'} = $newrecords;
    writeData($recipes);
    unlock($lock);
}

sub read_record
{
    my $count = shift;
    my $recipes = readDataWithLock();

    foreach my $r (@{$recipes->{'records'}}) {
	if ($r->{'count'} == $count) {
	    foreach my $i (@{$r->{'ingredients'}}) {
		$i->{'comment'} = "" if $i->{'comment'} eq "NIL";
	    }
	    return($r);
	}
    }
    return undef;
}

sub save_record
{
    my $query = shift;
    my $data = {};
    $data->{'title'} = $query->param('recipe_title');
    $data->{'count'} = $query->url_param('Count');

    my $row_count = $query->param('row_count');
    $row_count = 15 if $row_count eq "";
    $data->{'row_count'} = $row_count;

    for ($i = 1; $i < $row_count + 1; $i++) {
	my $ing = {};
	$ing->{'ord'} = $query->param("number_${i}");
	$ing->{'measure'} = $query->param("measure_${i}");
	$ing->{'amount'} = $query->param("amount_${i}");
	$ing->{'ingredient'} = $query->param("ingredient_${i}");
	$ing->{'comment'} = $query->param("comment_${i}");
	$ing->{'comment'} = "NIL" if $ing->{'comment'} eq "";
	if ($ing->{'measure'} eq "SectionHeading") {
	    $ing->{'amount'} = " ";
	    if ($ing->{'comment'} eq "NIL" && $ing->{'ingredient'} ne "") {
		$ing->{'comment'} = $ing->{'ingredient'};
	    }
	    $ing->{'ingredient'} = " ";
	    $ing->{'amount'} = " ";
	}
	push(@{$data->{'ingredients'}},$ing) unless $ing->{'ingredient'} eq "";
	my $dirs = {};
	$dirs->{'ord'} = $query->param("step_${i}");
	$dirs->{'text'} = $query->param("text_${i}");
	push(@{$data->{'directions'}},$dirs) 
	    unless $dirs->{'text'} eq "";
    }

    $data->{'directions'} = reorder($data->{'directions'});
    $data->{'ingredients'} = reorder($data->{'ingredients'});

    my $lockf = $DATAFILE.".lck";
    my $lock = lock($lockf);

    my $db = readData();
    if ($query->param('New') eq "1") {
	$db->{'count'} ++;
	$data->{'count'} = $db->{'count'};
	push(@{$db->{'records'}},$data);
    } else {
	foreach my $r (@{$db->{'records'}}) {
	    if ($r->{'count'} eq $data->{'count'}) {
		$r = $data;
	    }
	}
    }

    writeData($db);

    unlock($lock);
}

sub readData
{
    my $recipes = {};
    if (! -f $DATAFILE) {
        SBAS::XMLFile::write("Recipes",$recipes,$DATAFILE);
    }
    my $recname = SBAS::XMLFile::read($DATAFILE,\$recipes);
    return($recipes);		        
}

sub readDataWithLock
{
    my $recipes = {};
    if (! -f $DATAFILE) {
        SBAS::XMLFile::write("Recipes",$recipes,$DATAFILE);
    }
    my $lockf = $DATAFILE.".lck";
    my $lock = lock($lockf);
    my $recname = SBAS::XMLFile::read($DATAFILE,\$recipes);
    unlock($lock);
    return($recipes);		        
}

sub writeData
{
    my $recipes = shift;
    SBAS::XMLFile::write("Recipes",$recipes,$DATAFILE);
}

$LOCK_EX = 2;
$LOCK_UN = 8;

sub lock
{
    my $file = shift;
    my $lockavailable = 1;
    local(*LOCK);
    open(LOCK,">$file");
    if ($^O =~ /win32/i) {
	require Win32;
	if (Win32::IsWin95()) {
	    $lockavailable = 0;
	}
    }
    my $rv;
    if ($lockavailable) {
	$rv = flock(LOCK,$LOCK_EX);
    }
    return(*LOCK);
}

sub unlock
{
    my $lockref = shift;
    my $lockavailable = 1;
    if ($^O =~ /win32/i) {
	require Win32;
	if (Win32::IsWin95()) {
	    $lockavailable = 0;
	}
    }
    if ($lockavailable) {
	flock($lockref,$LOCK_UN);
    }
    close($lockref);
}

sub printENV
{
foreach $var (sort(keys(%ENV))) {
    $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    print "${var}=\"${val}\"\n";
}
}

sub printINC
{
foreach $var (@INC) {
    print "${var}\n";
    print "$var is a directory\n" if (-d $var);
    my @out = `ls $var`;
#    print @out;
    print "**********\n";
}
}

sub my_chdir
{
	my $d = shift;
	print $global_fh "cd $d\n";
	if ($TEST || $DEBUG) {
		return;
	}
	chdir($d);
}
 
sub my_system
{
	my $c = shift;
	if ($TEST || $DEBUG) {
		print $global_fh "$c\n";
		return;
	}
	system($c);
}

sub readFile
{
	my $f = shift;
	my $er = 0;
	open(IF,$f) || return (1,$!);
	my @if = <IF>;
	close(IF);
	return($er,@if);
}

sub reorder
{
    my $lr = shift;
    my $cnt = $#{$lr} + 1;
    my @rl = reverse(@$lr);
    my @rv = ();
    for ($i = 1; $i < $cnt + 1; $i ++) {
	foreach my $v (@rl) {
	    push(@rv,$v) if ($v->{'ord'} == $i);
	}
    }
    return(\@rv);
}



__END__
:endofperl






