package Utils::Files;
{

=encoding utf8

=head1 NAME

    Files utilites 

=cut

    use 5.012000;
    use strict;
    use warnings;
    use utf8;
    use Utils;
    use Data::Dumper;

    sub validate_file {
        my $self   = shift;
        my $fileid = $self->param('fileid');
        if (   $self->req->is_limit_exceeded
            || !$self->param('file.field')
            || !$self->param('file.field')->size )
        {
            $self->redirect_to( $self->param('path')
                  . '?error=1'
                  . ( $fileid ? "&fileid=$fileid" : '' ) );
            return (0);
        }
        return (1);
    }

    sub update_desc {
        my $self             = shift;
        my $fileid           = $self->param('fileid');
        my $pid              = $self->param('pid');
        my $file_description = $self->param('file.desc');

        my $path = get_path( $self, $pid );
        system "mkdir -p '$path/'" if !-d $path;

        # save file
        my $path2file = "$path/$fileid";

        # save file description
        set_file_content( $path2file . '.desc', $file_description )
          if $file_description;
        $self->redirect_to( $self->param('path')
              . "?fileform=update&fileid=$fileid&success=1" );
        return (1);
    }

    sub add {
        my $self = shift;
        my $pid  = $self->param('pid');

        return (0) if !validate_file($self);

        my $file = $self->param('file.field');
        my $path = get_path( $self, $pid );
        system "mkdir -p '$path/'" if !-d $path;

        # save file
        my $unique_file_name = Utils::get_date_uuid();
        $unique_file_name =~ tr/a-zA-Z0-9//cd;
        my $path2file = "$path/$unique_file_name";
        $file->move_to($path2file);

        # save file name
        set_file_content( $path2file . '.name', $file->filename );
        my $file_description = $self->param('file.desc');

        # save file description
        set_file_content( $path2file . '.desc', $file_description )
          if $file_description;
        $self->redirect_to( $self->param('path') . '?success=1' );
        return (1);
    }

    sub delete {
        my $self   = shift;
        my $fileid = $self->param('fileid');
        my $pid    = $self->param('pid');

        my $path      = get_path( $self, $pid );
        my $path2file = "$path/$fileid";

        unlink $path2file;
        unlink( $path2file . '.name' );
        unlink( $path2file . '.desc' );
        $self->redirect_to( $self->param('path') . '?success=1' );
    }

    sub update_file {
        my $self = shift;
        return (0) if !validate_file($self);
        my $pid       = $self->param('pid');
        my $fileid    = $self->param('fileid');
        my $file      = $self->param('file.field');
        my $file_path = get_path( $self, $pid ) . '/' . $fileid;
        $file->move_to($file_path);
        set_file_content( $file_path . '.name', $file->filename );
        $self->redirect_to( $self->param('path')
              . "?fileform=update&fileid=$fileid&success=1" );
        return (1);
    }

    sub get_path {
        my ( $self, $id ) = @_;
        $id =~ tr/a-zA-Z0-9//cd;

        my $prefix = $self->param('prefix') || $self->stash('controller');
        my $result;
        if ( $prefix =~ /templates/i ) {    # admin part
            $result = $self->app->home->rel_file("db/main/templates/$id");
            return ($result);
        }
        my $company_id = $self->session('company id');
        $company_id =~ tr/a-zA-Z0-9//cd;

        return ( $self->app->home->rel_file("db/clients/$company_id/$id") );
    }

    sub deploy {
        my ( $self, $id, $fileid ) = @_;
        my $path      = get_path( $self, $id );
        my $file_path = "$path/$fileid";
        return if !-e $file_path;
        $self->stash( 'file_name' => get_file_content( $file_path . '.name' ) )
          if -e ( $file_path . '.name' );
        $self->stash( 'file_desc' => get_file_content( $file_path . '.desc' ) )
          if -e ( $file_path . '.desc' );
    }

    sub files_count {
        my ( $self, $id ) = @_;
        my $path = get_path( $self, $id );
        return (0) if !-d $path;
        my @files = glob qq("$path/*.name");
        return ( scalar(@files) );
    }

    sub file_list4id {
        my ( $self, $id ) = @_;
        my $path = get_path( $self, $id );
        if ( !-d $path ) {
            system "mkdir -p '$path/'";
            return;
        }

        my $dir;
        opendir( $dir, $path );
        my $result = {};
        while ( my $fileid = readdir($dir) ) {
            next if ( $fileid =~ m/^\./ ) || ( $fileid =~ /[desc|name]$/ );
            $result->{$fileid} = {};
            $result->{$fileid}{name} =
              get_file_content( "$path/$fileid" . '.name' );
            $result->{$fileid}{desc} =
              get_file_content( "$path/$fileid" . '.desc' );
        }
        closedir($dir);
        return ($result);
    }

    sub set_file_content {
        my ( $file_path, $content ) = @_;
        return (undef) if !$file_path || !$content;
        my $fh;
        if ( open( $fh, "> :encoding(UTF-8)", $file_path ) ) {
            warn "Cannot write to $file_path: $!" if !( print $fh $content );
            warn "Cannot close $file_path: $!"    if !close($fh);
        }
        else { warn "Cannot open $file_path: $!" }
    }

    sub get_file_content {
        my $file_path = shift;
        return (undef) if !$file_path;
        my ( $fh, $content ) = ( undef, undef );
        if ( -e $file_path ) {
            if ( open( my $fh, "< :encoding(UTF-8)", $file_path ) ) {
                $content = do { local $/; <$fh> };
                warn "Cannot close $file_path: $!" if !close($fh);
            }
            else { warn "Cannot open $file_path: $!" }
            return ($content);
        }
        return (undef);
    }

    # END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
