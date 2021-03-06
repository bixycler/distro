package ZoneTests;

use strict;
use warnings;

use FoswikiFnTestCase();
our @ISA = qw( FoswikiFnTestCase );

sub set_up {
    my ($this) = @_;

    $this->SUPER::set_up();

    # Disable plugins which add noise
    $Foswiki::cfg{Plugins}{JQueryPlugin}{Enabled}  = 0;
    $Foswiki::cfg{Plugins}{TwistyPlugin}{Enabled}  = 0;
    $Foswiki::cfg{Plugins}{TablePlugin}{Enabled}   = 0;
    $Foswiki::cfg{Plugins}{CommentPlugin}{Enabled} = 0;
    $Foswiki::cfg{Plugins}{SmiliesPlugin}{Enabled} = 0;

    my $query = Unit::Request->new("");
    $query->path_info("/$this->{test_web}/$this->{test_topic}");

    $this->createNewFoswikiSession( undef, $query );

    return;
}

sub test_1 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml    = '%ADDTOZONE{zone="test" text=""}%';
    my $expect = "";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}->zones->_renderZone( "test", { format => '$item' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_2 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml    = '%ADDTOZONE{zone="test" text=""}%';
    my $expect = "";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}->zones()
      ->_renderZone( "test", { format => '$item $id' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_3 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml    = '%ADDTOZONE{zone="test" text="text"}%';
    my $expect = "text";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}->zones()->_renderZone( "test", { format => '$item' } );
    $this->assert_equals( $expect, $result );

    $result =
      $this->{session}->zones()->_renderZone( "test", { format => '$item' } );
    $this->assert_equals( '', $result );

    return;
}

sub test_4 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml    = '%ADDTOZONE{zone="test" id="id" text="item"}%';
    my $expect = "item=item id=id";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}
      ->zones()->_renderZone( "test", { format => 'item=$item id=$id' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_5 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml    = '%ADDTOZONE{zone="test1,test2" text="text"}%';
    my $expect = "text";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );

    my $result =
      $this->{session}->zones()->_renderZone( "test", { format => '$item' } );
    $this->assert_equals( '', $result );

    my $result1 =
      $this->{session}->zones()->_renderZone( "test1", { format => '$item' } );
    $this->assert_equals( $expect, $result1 );

    my $result2 =
      $this->{session}->zones()->_renderZone( "test2", { format => '$item' } );
    $this->assert_equals( $expect, $result2 );

    $this->assert_equals( $result1, $result2 );

    return;
}

sub test_6 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOZONE{zone="test" id="id1" text="text1"}%
%ADDTOZONE{zone="test" id="id1" text="text2"}%';
HERE
    my $expect = "text2";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}->zones()->_renderZone( "test", { format => '$item' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_7 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOZONE{zone="test" id="id1" text="text1"}%
%ADDTOZONE{zone="test" id="id2" text="text2" requires="id1"}%
HERE
    my $expect = "text1\ntext2";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}->zones()->_renderZone( "test", { format => '$item' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_8 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOZONE{zone="test" id="id1" text="text1"}%
%ADDTOZONE{zone="test" id="id2" text="text2" requires="id1"}%
HERE
    my $expect = "text1text2";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}
      ->zones()->_renderZone( "test", { format => '$item', separator => "" } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_9 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOZONE{zone="test" id="id1" text="text1" requires="id2"}%
%ADDTOZONE{zone="test" id="id2" text="text2"}%
HERE
    my $expect = "text2\ntext1";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}->zones()->_renderZone( "test", { format => '$item' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_10 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOZONE{zone="test" id="id2" text="text2"}%
%ADDTOZONE{zone="test" id="id3" text="text3" requires="id2"}%
%ADDTOZONE{zone="test" id="id1" text="text1" requires="id2,id3"}%
HERE
    my $expect = "text2\ntext3\ntext1";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}->zones()->_renderZone( "test", { format => '$item' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_11 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOZONE{zone="test" id="id1" text="text1" requires="id2"}%
HERE
    my $expect = "item=text1 id=id1";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}
      ->zones()->_renderZone( "test", { format => 'item=$item id=$id' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_12 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOZONE{zone="test" id="id1" text="text1" requires="id1"}%
HERE
    my $expect = "item=text1 id=id1";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}
      ->zones()->_renderZone( "test", { format => 'item=$item id=$id' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_13 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml    = '%ADDTOZONE{zone="test" text="text" id="id"}%';
    my $expect = "text<!--id-->";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result = $this->{session}->zones()->_renderZone("test");
    $this->assert_equals( $expect, $result );

    return;
}

sub test_addToHEAD_compatibility_1 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOZONE{zone="head" id="id1" text="text1" requires="id2"}%
%ADDTOHEAD{"id2" text="text2"}%
HERE
    my $expect = "text2\ntext1";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}->zones()->_renderZone( "head", { format => '$item' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub test_addToHEAD_compatibility_2 {
    my $this = shift;

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOHEAD{"id1" text="text1" requires="id2"}%
%ADDTOZONE{zone="head" id="id2" text="text2"}%
HERE
    my $expect = "text2\ntext1";

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result =
      $this->{session}->zones()->_renderZone( "head", { format => '$item' } );
    $this->assert_equals( $expect, $result );

    return;
}

sub _setMergeZones {
    my ( $this, $merge ) = @_;

    $Foswiki::cfg{MergeHeadAndScriptZones} = $merge;

    return;
}

sub test_HEAD_merged_with_SCRIPT {
    my $this = shift;
    $this->_setMergeZones(1);

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOHEAD{               "head1" text="text1" requires="head2"}%
%ADDTOZONE{zone="head" id="head2" text="this-text-will-be-ignored"}%
%ADDTOZONE{zone="head" id="head2" text="text2"}%
%ADDTOZONE{"script"      id="script3" text="text3" requires="script4"}%
%ADDTOZONE{zone="script" id="script4" text="text4" requires="head2"}%
%ADDTOHEAD{               "head5" text="text5" requires="script4,script3,script6"}%
%ADDTOZONE{zone="script" id="script6" text="text6" requires="head2,something-missing"}%
%ADDTOZONE{zone="head" id="misc7" text="head::misc7"}%
%ADDTOZONE{zone="script" id="misc7" text="script::misc7"}%
HERE

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result = "HEAD:\n" . $this->{session}->zones()->_renderZone( "head", );
    $result =
        $result
      . "\nSCRIPT:"
      . $this->{session}->zones()->_renderZone( "script", );

    foreach (
        'HEAD:.*?script::misc7<!--misc7-->.*?SCRIPT:$'
        ,    # Occurs somewhere, in HEAD zone
        'HEAD:.*?head::misc7<!--misc7-->.*?SCRIPT:$',  # Occurs anywhere in HEAD
        'HEAD:.*?text2<!--head2-->.*?text1<!--head1-->.*?SCRIPT:'
        ,                                              # text1 requires head2
'HEAD:.*?<!--script4-->.*?<!--script3-->.*?<!--script6: requires= missing ids: something-missing-->.*?text5<!--head5-->.*?SCRIPT:'
        ,    # head5 requires scripts 4, 3 & 6
        'HEAD:.*?text4<!--script4-->.*?text3<!--script3-->.*?SCRIPT:'
        ,    # script3 requires script4
'HEAD:.*?text2<!--head2-->.*?text6<!--script6: requires= missing ids: something-missing-->.*?SCRIPT:'
        ,    # script6 anywhere in SCRIPT zone
      )
    {
        $this->assert_matches( qr/$_/s, $result );
    }

    return;
}

sub test_HEAD_split_from_SCRIPT {
    my $this = shift;
    $this->_setMergeZones(0);

    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};

    my $tml = <<'HERE';
%ADDTOHEAD{               "head1" text="text1" requires="head2"}%
%ADDTOZONE{zone="head" id="head2" text="this-text-will-be-ignored"}%
%ADDTOZONE{zone="head" id="head2" text="text2"}%
%ADDTOZONE{"script"      id="script3" text="text3" requires="script4"}%
%ADDTOZONE{zone="script" id="script4" text="text4" requires="head2"}%
%ADDTOHEAD{               "head5" text="text5" requires="script4,script3,script6"}%
%ADDTOZONE{zone="script" id="script6" text="text6" requires="head2,something-missing"}%
%ADDTOZONE{zone="head" id="misc7" text="head::misc7"}%
%ADDTOZONE{zone="script" id="misc7" text="script::misc7"}%
HERE

    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result = "HEAD:\n" . $this->{session}->zones()->_renderZone("head");
    $result =
        $result
      . "\nSCRIPT:\n"
      . $this->{session}->zones()->_renderZone("script");

    foreach (
        "HEAD:.*?SCRIPT:.*?script::misc7<!--misc7-->"
        ,    # Occurs somewhere, in SCRIPT zone
        "HEAD:.*?head::misc7<!--misc7-->.*?SCRIPT:",   # Occurs anywhere in HEAD
        "HEAD:.*?text2<!--head2-->.*?text1<!--head1-->.*?SCRIPT:"
        ,                                              # text1 requires head2
"HEAD:.*?text5<!--head5: requires= missing ids: script3, script4, script6-->.*?SCRIPT:"
        ,    # head5 somewhere in HEAD zone
"SCRIPT:.*?text4<!--script4: requires= missing ids: head2-->.*?text3<!--script3-->"
        ,    # script3 requires script4
"SCRIPT:.*?text6<!--script6: requires= missing ids: head2, something-missing-->"
        ,    # script6 anywhere in SCRIPT zone
      )
    {
        $this->assert_matches( qr/$_/s, $result );
    }

    $this->assert_does_not_match( qr/this-text-will-be-ignored/, $result )
      ;      # Should not appear

    return;
}

sub test_explicit_RENDERZONE_merged {
    my $this = shift;
    $this->_setMergeZones(1);

    my $tml = <<'HERE';
<head>
%RENDERZONE{"head"}%
<!--end of rendered head-->
%ADDTOZONE{"head" id="head1" text="head_1"}%
%ADDTOZONE{"script" id="script1" text="script_1" requires="head1"}%
</head>
<body>
%RENDERZONE{"script"}%<!--script-->
</body>
HERE

    my $expect = <<'HERE';
<head>
head_1<!--head1-->
script_1<!--script1-->
<!--end of rendered head-->
<!--A2Z:head1-->
<!--A2Z:script1-->
</head>
<body>
<!--script-->
</body>
HERE
    chomp($expect);
    $tml = $this->{test_topicObject}->expandMacros($tml);
    my $result = $this->{session}->zones()->_renderZones($tml);
    $this->assert_str_equals( $expect, $result );

    return;
}

sub test_explicit_RENDERZONE_unmerged {
    my $this = shift;
    $this->_setMergeZones(0);

    my $tml = <<'HERE';
<head>
%RENDERZONE{"head"}%
<!--end of rendered head-->
%ADDTOZONE{"head" id="head1" text="head_1"}%
%ADDTOZONE{"script" id="script1" text="script_1" requires="head1"}%
</head>
<body>
%RENDERZONE{"script"}%<!--script-->
</body>
HERE

    my $expect = <<'HERE';
<head>
head_1<!--head1-->
<!--end of rendered head-->
<!--A2Z:head1-->
<!--A2Z:script1-->
</head>
<body>
script_1<!--script1: requires= missing ids: head1--><!--script-->
</body>
HERE
    chomp($expect);
    $tml = $this->{test_topicObject}->expandMacros($tml);
    my $result = $this->{session}->zones()->_renderZones($tml);
    $this->assert_str_equals( $expect, $result );

    return;
}

sub test_legacy_tag_param_compatibility {
    my $this = shift;
    $this->_setMergeZones(0);
    my $topicName = $this->{test_topic};
    my $webName   = $this->{test_web};
    my $tml       = <<'HERE';
 %ADDTOHEAD{                  "head1" text="text1" requires="head2"}%
 %ADDTOZONE{zone="head"    id="head2" text="this-text-will-be-ignored"}%
 %ADDTOZONE{zone="head"   tag="head2" text="text2"}%
 %ADDTOZONE{"script"      tag="script3" text="text3" requires="script4"}%
 %ADDTOZONE{zone="script" tag="script4" text="text4" requires="head2"}%
 %ADDTOHEAD{                    "head5" text="text5" requires="script4"}%
 %ADDTOZONE{zone="head"    id="misc7" text="head::misc7"}%
 %ADDTOZONE{zone="script"  id="misc7" text="script::misc7"}%
HERE
    Foswiki::Func::expandCommonVariables( $tml, $topicName, $webName );
    my $result = "HEAD:\n" . $this->{session}->zones()->_renderZone("head");
    $result =
        $result
      . "\nSCRIPT:\n"
      . $this->{session}->zones()->_renderZone("script");

    foreach (
        'HEAD:.*?head::misc7<!--misc7-->.*?SCRIPT:'
        ,    # Occurs somewhere, in HEAD zone
        'HEAD:.*?SCRIPT.*?script::misc7<!--misc7-->'
        ,    # Occurs anywhere in SCRIPT zone
        'HEAD:.*?text2<!--head2-->.*?text1<!--head1-->.*?SCRIPT:'
        ,    # text1 requires head2
        'HEAD:.*?text5<!--head5: requires= missing ids: script4-->.*?SCRIPT:'
        ,    # script req missing in head zone
        'HEAD:.*?SCRIPT:.*?text4<!--script4: requires= missing ids: head2-->.*?'
        ,    # head req missing in script
'HEAD:.*?SCRIPT:.*?text4<!--script4: requires= missing ids: head2-->.*?text3<!--script3-->'
        ,    # script3 requires scrip4
      )
    {
        $this->assert_matches( qr/$_/s, $result );
    }
    $this->assert_does_not_match( qr/this-text-will-be-ignored/, $result )
      ;      # Should not appear
    return;
}

sub test_header_footer_separator {
    my $this = shift;

    my $tml = <<'HERE';
<sausage>%RENDERZONE{"sausage" header="mash" footer="gravy"}%</sausage>
<egg>%RENDERZONE{"egg" header="toast$percent" footer="$percentpepper" separator="$quot"}%</egg>
<empty>%RENDERZONE{"empty" header="toast$percent" footer="$percentpepper" separator="$quot"}%</empty>
%ADDTOZONE{"egg" id="chicken" text="chicken" requires="boiling"}%
%ADDTOZONE{"egg" id="XXXX" text="rooster" requires="chicken"}%
%ADDTOZONE{"empty" id="null" text=""}%
HERE

    my $expect = <<'HERE';
<sausage></sausage>
<egg>toast%chicken<!--chicken: requires= missing ids: boiling-->"rooster<!--XXXX-->%pepper</egg>
<empty>toast%%pepper</empty>
<!--A2Z:chicken-->
<!--A2Z:XXXX-->
<!--A2Z:null-->
HERE
    chomp($expect);
    $tml = $this->{test_topicObject}->expandMacros($tml);
    my $result = $this->{session}->zones()->_renderZones($tml);
    $this->assert_str_equals( $expect, $result );

    return;
}

1;
