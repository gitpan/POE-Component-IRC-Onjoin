use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'			=> 'POE::Component::IRC::Onjoin',
    'VERSION_FROM'	=> 'Onjoin.pm',
    'PREREQ_PM'		=>
	{
		'POE'                 => '0.12',
		'POE::Component::IRC' => '1.0b',
	},
);
