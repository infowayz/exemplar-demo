$Repo = ${Env:GITHUB_REPOSITORY}
echo $Repo
$BaseUri = "https://api.github.com"
echo $BaseUri
$ArtifactUri = "$BaseUri/repos/$Repo/actions/artifacts"
echo $ArtifactUri
$Token = ${Env:GITHUB_TOKEN} | ConvertTo-SecureString -AsPlainText
echo $Token
echo ${Env:INPUT_ENCRYPTIONKEY}
$RestResponse = Invoke-RestMethod -Authentication Bearer -Uri $ArtifactUri -Token $Token | Select-Object -ExpandProperty artifacts
if ($RestResponse){
  $MostRecentArtifactURI = $RestResponse | Sort-Object -Property created_at -Descending | where name -eq "terraformstatefile" | Select-Object -First 1 | Select-Object -ExpandProperty archive_download_url
  Write-Host "Most recent artifact URI = $MostRecentArtifactURI"
  if ($MostRecentArtifactURI){
    Invoke-RestMethod -uri $MostRecentArtifactURI -Token $Token -Authentication bearer -outfile ./state.zip
    Expand-Archive state.zip
    openssl enc -d -in state/terraform.tfstate.enc -aes-256-cbc -pbkdf2 -pass pass:${Env:ENCRYPTION_KEY} -out terraform.tfstate
  }
}
terraform init
terraform plan 
terraform apply -auto-approve 

$StateExists = Test-Path -Path terraform.tfstate -PathType Leaf
if ($StateExists){
  echo "state file found, encrypting with the key"
  openssl enc -in terraform.tfstate -aes-256-cbc -pbkdf2 -pass pass:${Env:ENCRYPTION_KEY} -out terraform.tfstate.enc
}   
