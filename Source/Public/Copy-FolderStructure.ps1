<#
.SYNOPSIS
Recreates a folder and file structure to allow testing of the against a copy of the media source
files so that if something doesn't go as expected, the actual files are unchanged.

.DESCRIPTION
Will recreate a folder structure including all subfolder and files creating 0kb files

The test folder will the be saved in the root of the user profile directory unless a different
destination folder location was specified.

.PARAMETER SourceFolder
Specify the path to the folder that you want to create a test copy of.

.PARAMETER DestinationFolder
Specify the location to where you want the Test folder structure to be saved.  By Default it goes
to the root of the user profile directory.  This is because since the Format-TVShow function uses
the folder name to do the search, it needs to be saved in a different location since I don't want
to have the name of the top level folder changed in anyway.

.EXAMPLE
PS> Copy-FolderStructure './Warehouse 13/'

Will create a copy of every file and folder under the './Warehouse 13/' folder with the files
having 0k size and that copy folder will be located under the user home directory.

#>
Function Copy-FolderStructure {
    param(
        # The source folder whose structure needs to be copied
        [Parameter(
            Mandatory,
            Position = 0
        )]
        [IO.DirectoryInfo]
        $SourceFolder,

        # The destination folder where the structure will be copied, default is the user's profile directory
        [Parameter()]
        [IO.DirectoryInfo]
        $DestinationFolder = [Environment]::GetFolderPath('UserProfile')
    )

    # Create the root folder in the destination directory with the same name as the source folder
    $Path = (New-Item -ItemType Directory -Path $DestinationFolder -Name $(
            Split-Path $SourceFolder -Leaf) -ErrorAction Stop
    ).FullName

    # Tell user where destination folder is located.
    Write-Output "Copy folder created at $Path"

    # Get all items in the source folder recursively
    Get-ChildItem -Path $SourceFolder -Recurse
    | ForEach-Object {
        # Define ChildPath Path
        $ChildPath = (Split-Path $_.FullName).Replace($SourceFolder, '')

        # If the item is a directory, create the corresponding directory in the destination
        if ($_.Gettype().Name -eq 'DirectoryInfo') {
            New-Item -ItemType Directory -Path $(
                Join-Path -Path $Path -ChildPath $ChildPath
            ) -Name $_.BaseName
        }
        # If the item is a file, create a placeholder file in the corresponding location in the destination
        else {
            New-Item -Path $(
                [WildcardPattern]::Escape(
                    $(Join-Path -Path $Path -ChildPath $ChildPath)
                )
            ) -Name $_.Name
        }
    }
}