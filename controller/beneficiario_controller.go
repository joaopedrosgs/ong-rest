package controller

import (
	"errors"
	"projeto_bd/model"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo"
	_ "github.com/lib/pq"
)

type BeneficiarioController struct {
	conn *sqlx.DB
}

func NewBeneficiarioController() *BeneficiarioController {
	p := new(BeneficiarioController)
	var err error
	p.conn, err = sqlx.Connect("postgres", "postgres://root@localhost:5432/trabalho?sslmode=disable")
	if err != nil {
		println("Falha ao conectar: " + err.Error())
		return nil
	}
	return p
}
func (p *BeneficiarioController) Get(c echo.Context) error {
	cpf := c.Param("cpf")
	if cpf == "" {
		beneficiarios := []model.Pessoa{}
		err := p.conn.Select(&beneficiarios, "select * from pessoa where cpf in (SELECT cpf_pessoa FROM beneficiario)")
		if err != nil {
			println("Falha ao buscar beneficiario: " + err.Error())
			return err
		}

		return c.JSON(200, beneficiarios)
	} else {
		beneficiario := model.Pessoa{}
		err := p.conn.Get(&beneficiario, "select * from pessoa where cpf in (SELECT cpf_pessoa FROM beneficiario where cpf_pessoa = $1)", cpf)
		if err != nil {
			println("Falha ao buscar beneficiario: " + err.Error())
			return err
		}

		return c.JSON(200, beneficiario)
	}
}
func (p *BeneficiarioController) Put(c echo.Context) error {

	c.JSON(400, "Atualize a pessoa, não o beneficiario")
	return nil
}
func (p *BeneficiarioController) Post(c echo.Context) error {
	beneficiario := new(model.Beneficiario)
	err := c.Bind(beneficiario)
	if err != nil {
		return err
	}
	_, err = p.conn.Exec("INSERT into beneficiario values($1)", beneficiario.CpfPessoa)
	if err != nil {
		println("Falha ao inserir beneficiario: " + err.Error())
		return err
	}
	c.NoContent(400)
	return nil
}
func (p *BeneficiarioController) Delete(c echo.Context) error {
	cpf := c.Param("cpf")
	if cpf == "" {
		return errors.New("CPF vazio")
	}
	_, err := p.conn.Exec("delete from beneficiario where cpf_pessoa=$1", cpf)
	if err != nil {
		println("Falha ao deletar beneficiario: " + err.Error())
		return err
	}
	c.NoContent(400)
	return nil
}
