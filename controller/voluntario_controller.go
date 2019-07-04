package controller

import (
	"errors"
	"projeto_bd/model"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo"
	_ "github.com/lib/pq"
)

type VoluntarioController struct {
	conn *sqlx.DB
}

func NewVoluntarioController() *VoluntarioController {
	p := new(VoluntarioController)
	var err error
	p.conn, err = sqlx.Connect("postgres", "postgres://root@localhost:5432/trabalho?sslmode=disable")
	if err != nil {
		println("Falha ao conectar: " + err.Error())
		return nil
	}
	return p
}
func (p *VoluntarioController) Get(c echo.Context) error {
	cpf := c.Param("cpf")
	if cpf == "" {
		voluntarios := []model.Pessoa{}
		err := p.conn.Select(&voluntarios, "select * from pessoa where cpf in (SELECT cpf_pessoa FROM voluntario)")
		if err != nil {
			println("Falha ao buscar voluntario: " + err.Error())
			return err
		}
		return c.JSON(200, voluntarios)
	} else {
		voluntario := model.Pessoa{}
		err := p.conn.Get(&voluntario, "select * from pessoa where cpf in (SELECT cpf_pessoa FROM voluntario where cpf_pessoa = $1)", cpf)
		if err != nil {
			println("Falha ao buscar voluntario: " + err.Error())
			return err
		}
		return c.JSON(200, voluntario)
	}
}
func (p *VoluntarioController) Put(c echo.Context) error {

	c.JSON(400, "Atualize a pessoa, não o voluntario")
	return nil
}
func (p *VoluntarioController) Post(c echo.Context) error {
	voluntario := new(model.Voluntario)
	err := c.Bind(voluntario)
	if err != nil {
		return err
	}
	_, err = p.conn.Exec("INSERT into voluntario values($1)", voluntario.CpfPessoa)
	if err != nil {
		println("Falha ao inserir voluntario: " + err.Error())
		return err
	}
	c.NoContent(400)
	return nil
}
func (p *VoluntarioController) Delete(c echo.Context) error {
	cpf := c.Param("cpf")
	if cpf == "" {
		return errors.New("CPF vazio")
	}
	_, err := p.conn.Exec("delete from voluntario where cpf_pessoa=$1", cpf)
	if err != nil {
		println("Falha ao deletar voluntario: " + err.Error())
		return err
	}
	c.NoContent(400)
	return nil
}
