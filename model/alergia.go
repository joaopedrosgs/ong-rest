package model

type Alergia struct {
	CpfBeneficiario string `db:"cpf_beneficiario"`
	Remedio         string
	Alergia         string
}
