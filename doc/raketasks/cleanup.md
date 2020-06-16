# Clean up **(CORE ONLY)**

GitLab provides Rake tasks for cleaning up GitLab instances.

## Remove unreferenced LFS files from filesystem

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/36628) in GitLab 12.10.

DANGER: **Danger:**
Do not run this within 12 hours of a GitLab upgrade. This is to ensure that all background migrations
have finished, which otherwise may lead to data loss.

When you remove LFS files from a repository's history, they become orphaned and continue to consume
disk space. With this Rake task, you can remove invalid references from the database, which
will allow garbage collection of LFS files.

For example:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:orphan_lfs_file_references PROJECT_PATH="gitlab-org/gitlab-foss"

# installation from source
bundle exec rake gitlab:cleanup:orphan_lfs_file_references RAILS_ENV=production PROJECT_PATH="gitlab-org/gitlab-foss"
```

You can also specify the project with `PROJECT_ID` instead of `PROJECT_PATH`.

For example:

```shell
$ sudo gitlab-rake gitlab:cleanup:orphan_lfs_file_references PROJECT_PATH="gitlab-org/gitlab-foss"
I, [2019-12-13T16:35:31.764962 #82356]  INFO -- :  Looking for orphan LFS files for project GitLab Org / GitLab Foss
I, [2019-12-13T16:35:31.923659 #82356]  INFO -- :  Removed invalid references: 12
```

By default, this task does not delete anything but shows how many file references it can
delete. Run the command with `DRY_RUN=false` if you actually want to
delete the references. You can also use `LIMIT={number}` parameter to limit the number of deleted references.

Note that this Rake task only removes the references to LFS files. Unreferenced LFS files will be garbage-collected
later (once a day). If you need to garbage collect them immediately, run
`rake gitlab:cleanup:orphan_lfs_files` described below.

## Remove unreferenced LFS files

Unreferenced LFS files are removed on a daily basis but you can remove them immediately if
you need to. For example:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:orphan_lfs_files

# installation from source
bundle exec rake gitlab:cleanup:orphan_lfs_files
```

Example output:

```shell
$ sudo gitlab-rake gitlab:cleanup:orphan_lfs_files
I, [2020-01-08T20:51:17.148765 #43765]  INFO -- : Removed unreferenced LFS files: 12
```

## Remove garbage from filesystem

Clean up local project upload files if they don't exist in GitLab database. The
task attempts to fix the file if it can find its project, otherwise it moves the
file to a lost and found directory.

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:project_uploads

# installation from source
bundle exec rake gitlab:cleanup:project_uploads RAILS_ENV=production
```

Example output:

```shell
$ sudo gitlab-rake gitlab:cleanup:project_uploads

I, [2018-07-27T12:08:27.671559 #89817]  INFO -- : Looking for orphaned project uploads to clean up. Dry run...
D, [2018-07-27T12:08:28.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:28.689869 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:28.755624 #89817]  INFO -- : Can fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:28.760257 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
I, [2018-07-27T12:08:28.764470 #89817]  INFO -- : To cleanup these files run this command with DRY_RUN=false

$ sudo gitlab-rake gitlab:cleanup:project_uploads DRY_RUN=false
I, [2018-07-27T12:08:32.944414 #89936]  INFO -- : Looking for orphaned project uploads to clean up...
D, [2018-07-27T12:08:33.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:33.689869 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:33.755624 #89817]  INFO -- : Did fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:33.760257 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
```

Remove object store upload files if they don't exist in GitLab database.

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:remote_upload_files

# installation from source
bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production
```

Example output:

```shell
$ sudo gitlab-rake gitlab:cleanup:remote_upload_files

I, [2018-08-02T10:26:13.995978 #45011]  INFO -- : Looking for orphaned remote uploads to remove. Dry run...
I, [2018-08-02T10:26:14.120400 #45011]  INFO -- : Can be moved to lost and found: @hashed/6b/DSC_6152.JPG
I, [2018-08-02T10:26:14.120482 #45011]  INFO -- : Can be moved to lost and found: @hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg
I, [2018-08-02T10:26:14.120634 #45011]  INFO -- : To cleanup these files run this command with DRY_RUN=false
```

```shell
$ sudo gitlab-rake gitlab:cleanup:remote_upload_files DRY_RUN=false

I, [2018-08-02T10:26:47.598424 #45087]  INFO -- : Looking for orphaned remote uploads to remove...
I, [2018-08-02T10:26:47.753131 #45087]  INFO -- : Moved to lost and found: @hashed/6b/DSC_6152.JPG -> lost_and_found/@hashed/6b/DSC_6152.JPG
I, [2018-08-02T10:26:47.764356 #45087]  INFO -- : Moved to lost and found: @hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg -> lost_and_found/@hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg
```

## Remove orphan artifact files

When you notice there are more job artifacts files on disk than there
should be, you can run:

```shell
gitlab-rake gitlab:cleanup:orphan_job_artifact_files
```

This command:

- Scans through the entire artifacts folder.
- Checks which files still have a record in the database.
- If no database record is found, the file is deleted from disk.

By default, this task does not delete anything but shows what it can
delete. Run the command with `DRY_RUN=false` if you actually want to
delete the files:

```shell
gitlab-rake gitlab:cleanup:orphan_job_artifact_files DRY_RUN=false
```

You can also limit the number of files to delete with `LIMIT`:

```shell
gitlab-rake gitlab:cleanup:orphan_job_artifact_files LIMIT=100
```

This will only delete up to 100 files from disk. You can use this to
delete a small set for testing purposes.

If you provide `DEBUG=1`, you'll see the full path of every file that
is detected as being an orphan.

If `ionice` is installed, the tasks uses it to ensure the command is
not causing too much load on the disk. You can configure the niceness
level with `NICENESS`. Below are the valid levels, but consult
`man 1 ionice` to be sure.

- `0` or `None`
- `1` or `Realtime`
- `2` or `Best-effort` (default)
- `3` or `Idle`

## Remove expired ActiveSession lookup keys

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:sessions:active_sessions_lookup_keys

# installation from source
bundle exec rake gitlab:cleanup:sessions:active_sessions_lookup_keys RAILS_ENV=production
```