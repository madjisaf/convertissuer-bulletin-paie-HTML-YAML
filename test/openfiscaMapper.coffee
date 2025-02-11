mapper = require '../src/openfiscaMapper'


describe 'Mapper', ->
	describe 'OpenFisca object', ->
		NAME	= '3 . Taux unique sur tranches B et C (n° 5382).'
		ID		= 'test'
		PERIOD	= 'month:2015-01'
		SOURCE	=
			name	: NAME
			id		: ID
			period	: PERIOD
			data	: [
				{
					name: 'Salaire mensuel'
					inputAmount: '12 900,00'
				}, {
					name: 'Ass. maladie-solid. autonomie sur brut'
					base: '12 900,00'
					employeeBase: '0,75'
					employeeAmount: '96,75'
					employerBase: '13,10'
					employerAmount: '1 689,90'
				}
			]

		actual = mapper.toOpenFisca SOURCE

		it 'should have a name', ->
			actual.name.should.equal NAME

		it 'should have no id', ->
			actual.should.not.have.property 'id'

		it 'should have a period', ->
			actual.period.should.equal PERIOD

		it 'should have input variables', ->
			actual.input_variables.should.have.property 'salaire_de_base'
			actual.input_variables.salaire_de_base.should.equal 12900

		it 'should not have data', ->
			actual.should.not.have.property 'data'

		it 'should load id-specific values', ->
			actual.should.have.property 'test'
			actual.test.should.be.true

		describe 'output variables', ->
			it 'should have employer amount', ->
				actual.output_variables.should.have.property 'mmida_employeur'
				actual.output_variables.mmida_employeur.should.equal -1689.90

			it 'should have employee amount', ->
				actual.output_variables.should.have.property 'mmid_salarie'
				actual.output_variables.mmid_salarie.should.equal -96.75

		describe 'input variables', ->
			it 'should contain default values', ->
				actual.input_variables.should.have.property 'effectif_entreprise'
				actual.input_variables.effectif_entreprise.should.equal 25


	describe 'parseNumber', ->
		it 'should parse integers', ->
			mapper.parseNumber('12 900,00').should.equal 12900

		it 'should negate numbers if requested', ->
			mapper.parseNumber('1 689,90', '-').should.equal -1689.90


	describe 'mapRow', ->
		target = null

		beforeEach ->
			target = {
				input_variables: {},
				output_variables: {}
			}

		it 'should map an input variable to the matching OpenFisca input variable', ->
			mapper.mapRow.bind(target)({ name: 'Salaire mensuel' })
			target.input_variables.should.have.property 'salaire_de_base'

		it 'should map an input variable with end notes to the matching OpenFisca input variable', ->
			mapper.mapRow.bind(target)({ name: 'Salaire mensuel (1) (3) ' })
			target.input_variables.should.have.property 'salaire_de_base'

		it 'should sum elements with same targets', ->
			mapper.mapRow.bind(target)({ name: 'Salaire mensuel', inputAmount: 1 })
			mapper.mapRow.bind(target)({ name: 'Salaire mensuel 35 h', inputAmount: 2 })
			target.input_variables.salaire_de_base.should.equal 3

		it 'should respect mapped sign', ->
			mapper.mapRow.bind(target)({ name: 'NET FISCAL', employeeAmount: 1 })
			target.output_variables.salaire_imposable.should.equal 1
