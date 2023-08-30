param($Username)

    ##--------------------------------------------------------------------------
    ##  FUNCTION.......:  Show-ADPhoto
    ##  PURPOSE........:  Shows the photo stored in in an Active Directory User 
    ##                    Account.
    ##  REQUIREMENTS...:  PowerShell v2.0, Windows Server 2008 or newer Active 
    ##                    Directory.
    ##  NOTES..........:  
    ##--------------------------------------------------------------------------
    Function Show-ADPhoto {
        <#
        .SYNOPSIS
         Shows the photo stored in in an Active Directory User Account.
        .DESCRIPTION
         Reads the thumbnailPhoto attribute of the specified user's Active 
         Directory account, and displays the returned photo in a form window.
        .PARAMETER UserName
         The User logon name of the Active Directory user to query.
        .EXAMPLE
         C:\PS> Show-ADPhoto user1
         
         Displays the photo stored in the Active Directory user account with 
         the User logon name of "user1".
         
        .NOTES
         NAME......:  Show-ADPhoto
         AUTHOR....:  Joe Glessner
         LAST EDIT.:  28NOV11
         CREATED...:  28NOV11
        .LINK
         http://joeit.wordpress.com/
        #>
        
        [CmdletBinding()]             
            Param (                        
                [Parameter(Mandatory=$True, 
                    #ValueFromPipeline=$True,
                    #ValueFromPipelineByPropertyName=$True,
                    Position=0)]  
                [Alias('un')]
                [String]$UserName
            )#End: Param
        
        ##----------------------------------------------------------------------
        ##  Search AD for the user, set the path to the user account object.
        ##----------------------------------------------------------------------
        $Searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]"")
        $Searcher.Filter = "(&(ObjectClass=User)(SAMAccountName= $UserName))"
        $FoundUser = $Searcher.findOne()
        $P = $FoundUser | Select path
        Write-Verbose "Retrieving LDAP path for user $UserName ..."
        If ($FoundUser -ne $null) {
            Write-Verbose $P.Path
        }#END: If ($FoundUser -ne $null)
        Else {
            Write-Warning "User $UserName not found in this domain!"
            Write-Warning "Aborting..."
            Break;
        }#END: Else
        $User = [ADSI]$P.path
        
        ##----------------------------------------------------------------------
        ##  Build a form to display the image
        ##----------------------------------------------------------------------
        $Img = $User.Properties["thumbnailPhoto"].Value
        #$Img = $User.Properties["jpegPhoto"].Value
        [VOID][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $Form = New-Object Windows.Forms.Form
        $Form.Text = "Image stored in AD for $UserName"
        $Form.AutoSize = "True"
        $Form.AutoSizeMode = "GrowAndShrink"
        $PictureBox = New-Object Windows.Forms.PictureBox
        $PictureBox.SizeMode = "AutoSize"
        $PictureBox.Image = $Img
        $Form.Controls.Add($PictureBox)
        $Form.Add_Shown({$Form.Activate()})
        $Form.ShowDialog()
    }#END: Function Show-ADPhoto

    Show-ADPhoto -UserName $username