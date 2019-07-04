package controller

import (
	"errors"
	"projeto_bd/model"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo"
	_ "github.com/lib/pq"
)

type AlergiaController struct {
	conn *sqlx.DB
}

func NewAlergiaController() *AlergiaController {
	p := new(AlergiaController)
	var err error
	p.conn, err = sqlx.Connect("postgres", "postgres://root@localhost:5432/trabalho?sslmode=disable")
	if err != nil {
		println("Falha ao conectar: " + err.Error())
		return nil
	}
	return p
}
func (p *AlergiaController) Get(c echo.Context) error {
	cpf := c.Param("cpf")
	if cpf == "" {
		alergias := []model.Alergia{}
		err := p.conn.Select(&alergias, "select * from alergias")
		if err != nil {
			println("Falha ao buscar ss: " + err.Error())
			return err
		}
		return c.JSON(200, alergias)
	} else {
		alergia := model.Alergia{}
		err := p.conn.Get(&alergia, "select * from alergias where cpf_beneficiario = $1", cpf)
		if err != nil {
			println("Falha ao buscar alergia: " + err.Error())
			return err
		}
		return c.JSON(200, alergia)
	}
}
func (p *AlergiaController) Put(c echo.Context) error {

	c.JSON(400, "Atualize a pessoa, não o alergia")
	return nil
}
func (p *AlergiaController) Post(c echo.Context) error {
	alergia := new(model.Alergia)
	err := c.Bind(alergia)
	if err != nil {
		return err
	}
	_, err = p.conn.Exec("INSERT into alergias(cpf_beneficiario, alergia, remedio) values($1, $2, $3)", alergia.CpfBeneficiario, alergia.Alergia, alergia.Remedio)
	if err != nil {
		println("Falha ao inserir alergia: " + err.Error())
		return err
	}
	c.NoContent(400)
	return nil
}
func (p *AlergiaController) Delete(c echo.Context) error {
	cpf := c.Param("cpf")
	if cpf == "" {
		return errors.New("CPF vazio")
	}
	_, err := p.conn.Exec("delete from alergias where cpf_beneficiario=$1", cpf)
	if err != nil {
		println("Falha ao deletar alergia: " + err.Error())
		return err
	}
	c.NoContent(400)
	return nil
}
