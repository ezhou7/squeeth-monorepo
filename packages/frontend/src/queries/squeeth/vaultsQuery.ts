import { gql } from '@apollo/client'

export const VAULTS_QUERY = gql`
  query Vaults($ownerId: ID!, $vaultID: ID) {
    vaults(where: { owner: $ownerId }) {
      id
      shortAmount
      collateralAmount
      NftCollateralId
      owner {
        id
      }
      operator
    }
  }
`
export const VAULT_QUERY = gql`
  query Vault($vaultID: ID!) {
    vault(id: $vaultID) {
      id
      shortAmount
      collateralAmount
      NftCollateralId
      owner {
        id
      }
      operator
    }
  }
`
