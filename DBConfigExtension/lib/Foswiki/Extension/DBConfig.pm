# See bottom of file for license and copyright information

=begin TML

---+!! Class Foswiki::Extension::DBConfig

The main class providing extension functionality.

---++ Code description

First of all, this extension is not production ready. Though to get it ready
only a few minor touches are needed.

This extension utilizes two basic features of the new extensions framework:
pluggable methods and tag handlers.

The tag handler declares a new tag named =DBCONFIG_INFO= which does a very
simplistic thing: it outputs a table with connection parameters used to
initialize the extension.

All job is done by extending pluggable methods =readLSC=, =writeLSCStart=,
=writeLSCRecord=, and =writeLSCFinalize= as provided by =Foswiki::Config=.

---+++ Database Format

Configuration is stored in the database as a key/value pair accompanied with
comment field (*key*, *value*, *comment* table columns respectively). Keys are
stored with their full path notation; for example:

<verbatim>
Extensions.DBConfigExtension.Connection.Table
</verbatim>

Values and comments are stored one-to-one as passed over to
=Foswiki::Config::writeLSCRecord=. _undef_ values are stored as undefined in the
DB.

=cut

package Foswiki::Extension::DBConfig;

use DBI;
use Try::Tiny;

use Foswiki::FeatureSet;

use Foswiki::Class qw(extension);
extends qw(Foswiki::Extension);

use version 0.77; our $VERSION = version->declare(0.1.1);
our $API_VERSION = version->declare("2.99.0");

# Features this extension require to run.
our @FS_REQUIRED = qw( MOO OOSPECS );

features_provided
  -namespace => 'Ext::DBConfig',
  READ_WRITE =>
  [ 2.99, undef, undef, -desc => "Config could be read and written", ],
  MYSQL      => [ 2.99, undef, undef, -desc => "MySQL support", ],
  POSTGRESQL => [ 2.99, undef, undef, -desc => "PostgreSQL support", ];

=begin TML

---++ Object Attributes

=cut

=begin TML

---+++ ObjectAttribute dbh

Initialized instance database handle object returned by [[CPAN:DBI]] =connect()= method.

See =prepareDbh= method.

=cut

has dbh => (
    is        => 'rw',
    lazy      => 1,
    clearer   => 1,
    predicate => 1,
    builder   => 'prepareDbh',
);

=begin TML

---+++ ObjectAttribute sth

Initialized instance of a statement handle, as returned by [[CPAN:DBI]]
=prepare= method.

=cut

has sth => (
    is      => 'rw',
    clearer => 1,
);

=begin TML

---+++ ObjectAttribute data

Cached reference to =$app->cfg->data= hash. Initialized by
DBConfig's =readLSC= method extension.

=cut

has data => ( is => 'rw', );

=begin TML

---+++ ObjectAttribute mode

Text to indicate if we're reading or writing LSC. Used for error reporting.

=cut 

has mode => ( is => 'rw', );

=begin TML

---++ Methods and method extenders

=cut

=begin TML

---+++ ObjectMethod readLSC

This is an extender for corresponding =Foswiki::Config= pluggable method.

Contrary to how the extension deals with writing of LSC,
readLSC{Start|Record|Finalize} cannot be used because there is dependcy on
database connection info stored in the local LSC file. This is also the reason
for using plugAfter: at this stage it's guaranteed that the local file has been
read by =Foswiki::Config=.

Basically, =readLSC= does nothing more than fetching key/value pairs from the database,
converts value from Perl code to pure data by =eval='ing it stores the result into
the configuration data hash by calling =Foswiki::Config::set= method.

---++++ Error processing

If any exception is thrown at this stage it would basically be ignored
and only a warning will be issued with text generated by =Foswiki::Exception='s
=stringify()= method. The exception could be cause by either a [[cpan:DBI]]
error, or syntax eror within eval as the most common causes.

This approach to error handling has been chosen with the reasoning in mind that
this extension is not mandatory for site funtioning and that admin must be given a chance
to proceed further with possibly fixing the problem by running configure or fetching
more information by using any other means provided by %WIKITOOLNAME%.

For now the error is only reported by issuing a call to Perl's =warn= function
and enforcing =readLSC= return value to a false value (=0=). Though use of
=warn= is undesirable because it causes fatal exception when DEBUG is on. Yet,
even if not causing application death it sends output to a log file only. As
soon as =Foswiki::App= will have bufferized broadcast messaging support it must
come in place of the =warn= call.

=cut

plugAfter 'Foswiki::Config::readLSC' => sub {
    my $this = shift;    # This is extension object, not the Foswiki::Config
    my ($params) = @_;

    # Do nothing if LSC reading has already failed.
    return if $params->{rc};

    $this->mode('read');

    my $cfg = $params->{object};    # This is Foswiki::Config

    my %callParams = @{ $params->{args} };
    my $cfgData = $callParams{data} // $cfg->data;
    $this->data($cfgData);

    my $connData = $cfgData->{Extensions}{DBConfigExtension}{Connection};

    # SMELL We expect all connection data to be in place if the Connection key
    # is defined. Fair enough for testing but better be fully validated for the
    # production use.
    if ( defined $connData ) {
        try {
            my $dbh = $this->dbh;

            my $tblName =
              $this->data->{Extensions}{DBConfigExtension}{Connection}{Table}
              // 'LSC';

            my $records =
              $dbh->selectall_arrayref("SELECT `key`, value FROM $tblName");

            foreach my $rec (@$records) {
                my ( $keyPath, $keyVal ) = @$rec;
                if ( defined $keyVal ) {
                    my $interp = eval $keyVal;
                    if ($@) {
                        Foswiki::Exception::Harmless->throw(
                            text => "Syntax error in value '$keyVal': $@" );
                    }
                    $keyVal = $interp;
                }

                $cfg->set( $keyPath, $keyVal, data => $cfgData, );
            }

        }
        catch {
            my $e = Foswiki::Exception::Fatal->transmute( $_, 0 );

            # For this moment it doesn't matter what kind of exception has been
            # caught. Just warn and return FALSE.
            warn $e->stringify;

            $params->{rc} = 0;
        };
    }
};

=begin TML

---+++ ObjectMethod writeLSCStart

Extends corresponding =Foswiki::Config= method. Prepares the database for
writing by clearing up the configuration table of the old records and preparing
a new statement handle.

The table would be locked until writing of the new config is done for a good or
a bad reason.

=cut

plugAround 'Foswiki::Config::writeLSCStart' => sub {
    my $this = shift;
    my ($params) = @_;

    #my $cfg = $params->{object};    # This is Foswiki::Config

    $this->mode('write');

    my %callParams = @{ $params->{args} };

    $this->clear_dbh;
    $this->data( $callParams{data} );

    my $dbh = $this->dbh;

    my $tblName =
      $this->data->{Extensions}{DBConfigExtension}{Connection}{Table} // 'LSC';

    $dbh->do( 'DELETE FROM ' . $tblName );

    my $statement =
        'INSERT INTO `'
      . $tblName
      . '` (`key`,`value`,`comment`) VALUES (?, ?, ?)';
    my $sth = $dbh->prepare($statement);

    $this->sth($sth);
};

=begin TML

---+++ ObjectMethod writeLSCRecord

Extends corresponding =Foswiki::Config= method. Writes a record to the databse.

=cut

plugAround 'Foswiki::Config::writeLSCRecord' => sub {
    my $this = shift;
    my ($params) = @_;

    my $cfg = $params->{object};    # This is Foswiki::Config

    my %callParams = @{ $params->{args} };

    #say STDERR "Writing to DBConfig: $callParams{key}='"
    #  . ( $callParams{value} // '' ), "'";

    my ( $keyPath, $keyVal, $comment ) = @callParams{qw(key value comment)};

    # SMELL Temporary solution to automate replacement of $Foswiki::cfg with ${}
    # macro format.
    $keyVal =~ s/\$Foswiki::cfg\{/\$\{/g if defined $keyVal && !ref($keyVal);

    $this->sth->execute( $keyPath, $keyVal, $comment );
};

=begin TML

---+++ ObjectMethod writeLSCFinalize

Extends corresponding =Foswiki::Config= method. Commits all changes and
disconnects from the database.

=cut

plugAround 'Foswiki::Config::writeLSCFinalize' => sub {
    my $this = shift;

    #my ($params) = @_;

    #my $cfg = $params->{object};    # This is Foswiki::Config

    #my %callParams = @{ $params->{args} };

    $this->dbh->commit;
    $this->dbh->disconnect;
    $this->clear_dbh;
};

=begin TML

---+++ tagHandler DBCONFIG_INFO

Outputs a table with this extension's version and connection information.

=cut

tagHandler DBCONFIG_INFO => sub {
    my $this = shift;

    my $text = "*DBConfig Extension " . $VERSION . "*\n";

    my $connData =
      $this->app->cfg->data->{Extensions}{DBConfigExtension}{Connection};

    foreach my $kw (qw(Driver Host Port Database Table)) {
        $text .=
          "| *$kw* |  " . ( "=$connData->{$kw}=" // '_unknown_' ) . "|\n";
    }

    return $text;
};

=begin TML

---+++ ObjectMethod prepareDbh

Builder for the =dbh= attribute of the extension's object. Connects to a
database using information from =Extensions.DBConfigExtension.Connection=
configuration key.

=cut 

sub prepareDbh {
    my $this = shift;

    my $cfgData = $this->data;

    my $connData = $cfgData->{Extensions}{DBConfigExtension}{Connection};

    my $dsn = "DBI:"
      . $connData->{Driver}
      . ":database="
      . $connData->{Database}
      . ";host="
      . $connData->{Host};

    $dsn .= ";port" . $connData->{Port}
      if defined $connData->{Port};

    # Avoid strong circular dependency via HandleError callback referring back
    # to $this.
    my $_this = $this;
    use Scalar::Util qw(weaken);
    weaken($_this);

    my $dbh = DBI->connect(
        $dsn,
        $connData->{User},
        $connData->{Password},
        {
            AutoCommit  => 0,
            RaiseError  => 1,
            PrintError  => 0,
            HandleError => sub {
                $_this->_dbiError(@_);
            },
        }
    );

    # SMELL Must be some kind of Foswiki::Exception::Config:: exception. Fatal
    # is used for test purposes only.
    Foswiki::Exception::Fatal->throw(
            text => "Failed to connect to database '"
          . $connData->{Database} . ": "
          . $DBI::errstr, )
      unless defined $dbh;

    return $dbh;
}

=begin TML

---+++ ObjectMethod _dbiError

Called by =HandleError= callback of =[[cpan:DBI]]. Rollbacks current transaction,
disconnects and throws a fatal exception.

=cut

sub _dbiError {
    my $this = shift;

    if ( $this->has_dbh && defined $this->dbh ) {
        $this->dbh->rollback;
        $this->dbh->disconnect;
        $this->clear_dbh;
    }

    # SMELL Must be some kind of Foswiki::Exception::Config:: exception. Fatal
    # is used for test purposes only.
    Foswiki::Exception::Fatal->throw(
        text => "Database config " . $this->mode . " failed: " . $_[0], );
}

=begin TML


---++ SEE ALSO

=Foswiki::Extensions=, =Foswiki::Extension=, =Foswiki::Class=, and
=ExtensionsTests= test suite.

=cut

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2017 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
